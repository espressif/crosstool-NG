# This file contains crosstool-NG internal steps

create_ldso_conf()
{
    local multi_dir multi_os_dir multi_os_dir_gcc multi_root multi_flags multi_index multi_count multi_target
    local b d

    for arg in "$@"; do
        eval "${arg// /\\ }"
    done

    CT_DoExecLog ALL mkdir -p "${multi_root}/etc"
    for b in /lib /usr/lib "${CT_LDSO_CONF_EXTRA_DIRS_ARRAY[@]}"; do
        d="${b}/${multi_os_dir}"
        CT_SanitizeVarDir d
        echo "${d}" >> "${multi_root}/etc/ld.so.conf"
        if [ "${multi_os_dir}" != "${multi_os_dir_gcc}" ]; then
            d="${b}/${multi_os_dir_gcc}"
            CT_SanitizeVarDir d
            echo "${d}" >> "${multi_root}/etc/ld.so.conf"
        fi
    done
}

create_cmake_toolchain()
{
    local system

    if [ "${CT_KERNEL_LINUX}" = "y" ]; then
        system=Linux
    elif [ "${CT_KERNEL_WINDOWS}" = "y" ]; then
        system=Windows
    else
        # Assume bare metal
        system=Generic
    fi

    echo "\
set(CMAKE_SYSTEM_NAME @@SYSTEM@@)
set(CMAKE_SYSTEM_PROCESSOR @@CT_TARGET_ARCH@@)

set(CMAKE_C_COMPILER \${CMAKE_CURRENT_LIST_DIR}/bin/@@CT_TARGET@@-gcc)
set(CMAKE_CXX_COMPILER \${CMAKE_CURRENT_LIST_DIR}/bin/@@CT_TARGET@@-g++)

set(CMAKE_FIND_ROOT_PATH \${CMAKE_CURRENT_LIST_DIR}/@@CT_TARGET@@/sysroot)
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)" \
    | sed -r -e 's|@@SYSTEM@@|'"${system}"'|g;'       \
             -e 's|@@CT_TARGET@@|'"${CT_TARGET}"'|g;' \
             -e 's|@@CT_TARGET_ARCH@@|'"${CT_TARGET_ARCH}"'|g;'     \
             > "${CT_PREFIX_DIR}/toolchain.cmake"
}

CT_StripDebugForHost()
{
    local objcopy readelf f d dest rel rel_sum listfile scanlist
    local debug_root sumfile
    local -a scan_roots

    CT_DoLog EXTRA "Stripping target debug info for ${CT_TARGET}"
    objcopy="${CT_BUILDTOOLS_PREFIX_DIR}/${CT_TARGET}/bin/objcopy"
    readelf="${CT_BUILDTOOLS_PREFIX_DIR}/${CT_TARGET}/bin/readelf"
    CT_TestOrAbort "Missing ${objcopy} for STRIP_TARGET_TOOLCHAIN_LIBRARIES" -x "${objcopy}"
    CT_TestOrAbort "Missing ${readelf} for STRIP_TARGET_TOOLCHAIN_LIBRARIES" -x "${readelf}"

    if [ "${CT_STRIP_TARGET_TOOLCHAIN_LIBRARIES_SAVE_DEBUG}" = "y" ]; then
        debug_root="$(dirname "${CT_PREFIX_DIR}")/${CT_TARGET}/debug-sections"
        sumfile="${debug_root}/checksums.sha256sum"
        listfile="${debug_root}/split-target-debug.list"
        CT_DoLog EXTRA "Removing prior split-debug tree and checksum"
        CT_DoForceRmdir "${debug_root}"
        CT_DoExecLog ALL mkdir -p "${debug_root}"
        rm -f "${sumfile}"
        : > "${listfile}"
    fi

    scanlist="${CT_BUILD_DIR}/${CT_TARGET}-objects.list"
    find "${CT_PREFIX_DIR}" -type f \( \
        -name '*.o' -o -name '*.a' \
    \) -print0 | LC_ALL=C sort -z -u > "${scanlist}"

    while IFS= read -r -d '' f; do
        "${readelf}" -h "${f}" >/dev/null 2>&1 || continue
        if [ "${CT_STRIP_TARGET_TOOLCHAIN_LIBRARIES_SAVE_DEBUG}" = "y" ]; then
            d="${f}.debug"
            if ! "${objcopy}" --only-keep-debug "${f}" "${d}" >>"${CT_BUILD_LOG}" 2>&1; then
                CT_DoLog EXTRA "objcopy --only-keep-debug failed (skipping): ${f}"
                rm -f "${d}"
                continue
            fi
            # Skip if debug file missing or empty (nothing to split out; do not strip ${f}).
            if [ ! -s "${d}" ]; then
                rm -f "${d}"
                continue
            fi
        fi
        CT_DoExecLog ALL "${objcopy}" --strip-debug "${f}"
        if [ "${CT_STRIP_TARGET_TOOLCHAIN_LIBRARIES_SAVE_DEBUG}" = "y" ]; then
            rel="${f#${CT_PREFIX_DIR}/}"
            dest="${debug_root}/${CT_TARGET}/${rel}.debug"
            CT_DoExecLog ALL mkdir -p "$(dirname "${dest}")"
            CT_DoExecLog ALL mv "${d}" "${dest}"
            printf '%s\n' "${CT_TARGET}/${rel}" >> "${listfile}"
        fi
    done < "${scanlist}"
    rm -f "${scanlist}"

    if [ -s "${listfile}" ]; then
        LC_ALL=C sort -u "${listfile}" -o "${listfile}"
        CT_DoLog EXTRA "Checksumming split-debug artifacts into ${sumfile}"
        CT_Pushd "${CT_PREFIX_DIR}/.."
        : > "${sumfile}"
        while IFS= read -r rel_sum || [ -n "${rel_sum}" ]; do
            [ -n "${rel_sum}" ] || continue
            sha256sum "${rel_sum}" >> "${sumfile}"
        done < "${listfile}"
        CT_Popd
    fi
    rm -f "${listfile}"
}

# This step is called once all components were built, to remove
# un-wanted files, to add tuple aliases, and to add the final
# crosstool-NG-provided files.
do_finish() {
    local _t
    local _type
    local strip_args
    local gcc_version
    local exe_suffix
    local tarball

    CT_DoStep INFO "Finalizing the toolchain's directory"

    if [ "${CT_STRIP_TARGET_TOOLCHAIN_LIBRARIES}" = "y" ]; then
        CT_StripDebugForHost
    fi

    if [ "${CT_CREATE_LDSO_CONF}" = "y" ]; then
        # Create /etc/ld.so.conf
        CT_mkdir_pushd "${CT_BUILD_DIR}/build-create-ldso"
        CT_IterateMultilibs create_ldso_conf create-ldso
        CT_Popd
    fi

    if [ "${CT_STRIP_HOST_TOOLCHAIN_EXECUTABLES}" = "y" ]; then
        case "$CT_HOST" in
            *darwin*)
                strip_args=""
                ;;
            *freebsd*)
                strip_args="--strip-all"
                ;;
            *)
                strip_args="--strip-all -v"
                ;;
        esac
        case "$CT_TARGET" in
            *mingw*)
                exe_suffix=".exe"
                ;;
            *)
                exe_suffix=""
                ;;
        esac
        CT_DoLog INFO "Stripping all toolchain executables"
        CT_Pushd "${CT_PREFIX_DIR}"

        # Strip gdbserver
        if [ "${CT_GDB_GDBSERVER}" = "y" ]; then
            CT_DoExecLog ALL "${CT_TARGET}-strip" ${strip_args}         \
                             "${CT_TARGET}/debug-root/usr/bin/gdbserver${exe_suffix}"
        fi
        if [ "${CT_CC_GCC}" = "y" ]; then
            # We can not use the version in CT_GCC_VERSION because
            # of the Linaro stuff. So, harvest the version string
            # directly from the gcc sources...
            gcc_version=$( cat "${CT_SRC_DIR}/gcc/gcc/BASE-VER" )
            for _t in "bin/${CT_TARGET}-"*                                      \
                      "${CT_TARGET}/bin/"*                                      \
                      "libexec/gcc/${CT_TARGET}/${gcc_version}/"*               \
                      "libexec/gcc/${CT_TARGET}/${gcc_version}/install-tools/"* \
            ; do
                _type="$( file "${_t}" |cut -d ' ' -f 2- )"
                case "${_type}" in
                    *script*executable*)
                        ;;
                    *executable*|*shared*object*)
                        CT_DoExecLog ALL ${CT_HOST}-strip ${strip_args} "${_t}"
                        ;;
                esac
            done
        fi
        CT_Popd
    fi

    if [ "${CT_BARE_METAL}" != "y" ]; then
        CT_DoLog EXTRA "Installing the populate helper"
        sed -r -e 's|@@CT_TARGET@@|'"${CT_TARGET}"'|g;' \
               -e 's|@@CT_install@@|'"install"'|g;'     \
               -e 's|@@CT_awk@@|'"awk"'|g;'             \
               -e 's|@@CT_bash@@|'"${bash}"'|g;'           \
               -e 's|@@CT_grep@@|'"grep"'|g;'           \
               -e 's|@@CT_make@@|'"make"'|g;'           \
               -e 's|@@CT_sed@@|'"sed"'|g;'             \
               "${CT_LIB_DIR}/scripts/populate.in"         \
               >"${CT_PREFIX_DIR}/bin/${CT_TARGET}-populate"
        CT_DoExecLog ALL chmod 755 "${CT_PREFIX_DIR}/bin/${CT_TARGET}-populate"
    fi

    if [ "${CT_LIBC_XLDD}" = "y" ]; then
        CT_DoLog EXTRA "Installing a cross-ldd helper"
        sed -r -e 's|@@CT_VERSION@@|'"${CT_VERSION}"'|g;' \
               -e 's|@@CT_TARGET@@|'"${CT_TARGET}"'|g;'      \
               -e 's|@@CT_BITS@@|'"${CT_ARCH_BITNESS}"'|g;'  \
               -e 's|@@CT_install@@|'"install"'|g;'       \
               -e 's|@@CT_bash@@|'"${bash}"'|g;'             \
               -e 's|@@CT_grep@@|'"grep"'|g;'             \
               -e 's|@@CT_make@@|'"make"'|g;'             \
               -e 's|@@CT_sed@@|'"sed"'|g;'               \
               "${CT_LIB_DIR}/scripts/xldd.in"               \
               >"${CT_PREFIX_DIR}/bin/${CT_TARGET}-ldd"
        CT_DoExecLog ALL chmod 755 "${CT_PREFIX_DIR}/bin/${CT_TARGET}-ldd"
    fi

    if [ "${CT_TOOLCHAIN_CMAKE_TOOLCHAIN_FILE}" = "y" ]; then
        CT_DoLog EXTRA "Installing a cmake toolchain file"
        create_cmake_toolchain
    fi

    # Create the aliases to the target tools
    CT_DoLog EXTRA "Creating toolchain aliases"
    CT_SymlinkTools "${CT_PREFIX_DIR}/bin" "${CT_PREFIX_DIR}/bin" \
            "${CT_TARGET_ALIAS}" "${CT_TARGET_ALIAS_SED_EXPR}"

    # Remove the generated documentation files
    if [ "${CT_REMOVE_DOCS}" = "y" ]; then
        CT_DoLog EXTRA "Removing installed documentation"
        CT_DoForceRmdir "${CT_PREFIX_DIR}/"{,usr/}{,share/}{man,info}
        CT_DoForceRmdir "${CT_SYSROOT_DIR}/"{,usr/}{,share/}{man,info}
        CT_DoForceRmdir "${CT_DEBUGROOT_DIR}/"{,usr/}{,share/}{man,info}
    fi

    if [ "${CT_INSTALL_LICENSES}" = y ]; then
        CT_InstallCopyingInformation
    fi

    if [ "${CT_TARBALL_RESULT}" = y ]; then
        tarball="${CT_TARBALL_RESULT_DIR}/${CT_TARBALL_RESULT_FILENAME}.tar.xz"
        CT_DoLog EXTRA "Creating binary toolchain tarball: ${tarball}"
        cp "${CT_TOP_DIR}/.config" "${CT_PREFIX_DIR}/${CT_TOOLCHAIN_PKGVERSION}.config"
        (cd "${CT_PREFIX_DIR}" && \
            find ./. -print0 | \
                LC_ALL=C sort -z | \
                tar --numeric-owner --owner=0 --group=0 \
                    --transform "s,^\./\.,${CT_TARBALL_RESULT_FILENAME},S" \
                    --no-recursion --null -T - -Jcf "${tarball}")
        CT_DoLog EXTRA "Calculating binary toolchain checksum"
        sha256sum "${tarball}" > "${tarball}.asc"
    fi

    CT_EndStep
}
