do_xtensaconfig_get() { :; }
do_xtensaconfig_extract() { :; }
do_xtensaconfig_for_build() { :; }
do_xtensaconfig_for_host() { :; }
do_xtensaconfig_for_target() { :; }

# Overide functions depending on configuration
if [ "${CT_XTENSACONFIG}" = "y" ]; then

do_xtensaconfig_get() {
    CT_Fetch XTENSACONFIG
}

do_xtensaconfig_extract() {
    CT_ExtractPatch XTENSACONFIG
}

do_xtensaconfig_for_build() {
    local -a opts

    case "${CT_TOOLCHAIN_TYPE}" in
        native|cross)   return 0;;
    esac

    CT_DoStep INFO "Installing Xtensaconfig for build"
    CT_mkdir_pushd "${CT_BUILD_DIR}/build-xtensaconfig-build-${CT_BUILD}"

    opts+=( "host=${CT_BUILD}" )
    opts+=( "prefix=${CT_BUILDTOOLS_PREFIX_DIR}" )
    opts+=( "cflags=${CT_CFLAGS_FOR_BUILD}" )
    opts+=( "ldflags=${CT_LDFLAGS_FOR_BUILD}" )
    
    # BUILD
    # ...
    #

    CT_Popd
    CT_EndStep
}

do_xtensaconfig_for_host() {
    local -a opts

    CT_DoStep INFO "Installing Xtensaconfig for host"
    CT_mkdir_pushd "${CT_BUILD_DIR}/build-xtensaconfig-host-${CT_HOST}"

    opts+=( "host=${CT_HOST}" )
    opts+=( "prefix=${CT_HOST_COMPLIBS_DIR}" )
    opts+=( "cflags=${CT_CFLAGS_FOR_HOST}" )
    opts+=( "ldflags=${CT_LDFLAGS_FOR_HOST}" )

    # BUILD
    # ...
    #

    CT_Popd
    CT_EndStep
}

do_xtensaconfig_install()
{
    #FIXME

    CT_DoLog EXTRA "Copying xtensaconfig libs"
    CT_DoExecLog EXTRA cp -av ${XTENSACONFIG_LIB_BIN}/*.so "${prefix}/lib"

#TODO it doesn't work well, $gcc_version is not defined.
    CT_DoExecLog EXTRA mkdir -p "${prefix}/libexec/gcc/${CT_TARGET}/8.2.0/lib"
    CT_DoExecLog EXTRA cp -av ${XTENSACONFIG_LIB_BIN}/*.so "${prefix}/libexec/gcc/${CT_TARGET}/8.2.0/lib"

    CT_DoExecLog EXTRA mkdir -p "${prefix}/libexec/gcc/${CT_TARGET}/lib"
    CT_DoExecLog EXTRA cp -av ${XTENSACONFIG_LIB_BIN}/*.so "${prefix}/libexec/gcc/${CT_TARGET}/lib"

    CT_DoExecLog EXTRA cp -av ${XTENSACONFIG_LIB_BIN}/*.so "${CT_PREFIX_DIR}/lib"

    CT_DoExecLog EXTRA mkdir -p "${CT_PREFIX_DIR}/${CT_TARGET}/lib"
    CT_DoExecLog EXTRA cp -av ${XTENSACONFIG_LIB_BIN}/*.so "${CT_PREFIX_DIR}/${CT_TARGET}/lib"

    CT_DoExecLog EXTRA mkdir -p "${CT_PREFIX_DIR}/libexec/gcc/${CT_TARGET}/lib"
    CT_DoExecLog EXTRA cp -av ${XTENSACONFIG_LIB_BIN}/*.so "${CT_PREFIX_DIR}/libexec/gcc/${CT_TARGET}/lib"
}

fi # CT_XTENSACONFIG
