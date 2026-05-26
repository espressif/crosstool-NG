# Compute RISC-V-specific values

CT_DoArchTupleValues() {
    CT_TARGET_ARCH="riscv${CT_ARCH_BITNESS}"
}

# Multilib: Adjust configure arguments for GLIBC
# Usage: CT_DoArchGlibcAdjustConfigure <configure-args-array-name> <cflags> <multilib-dir>
CT_DoArchGlibcAdjustConfigure() {
    local -a add_args
    local array="${1}"
    local multi_dir="${3}"

    # If building for multilib, set proper installation paths
    if [ "${CT_MULTILIB}" = "y" ]; then
        # GLIBC generates the correct path for the default (empty) directory name
        # (lib64/lp64d or lib32/ilp32), but more complex cases require explicit
        # *libdir settings.
        if [ -n "${multi_dir}" ] && [ "${multi_dir}" != "." ]; then
            add_args+=("--libdir=/usr/${multi_dir}")
            add_args+=("libc_cv_slibdir=/${multi_dir}")
            add_args+=("libc_cv_rtlddir=/lib")
        fi
    fi

    eval "${array}+=( \"\${add_args[@]}\" )"
}
