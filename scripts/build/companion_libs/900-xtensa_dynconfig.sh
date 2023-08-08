# This file adds functions to build the xtensa-dynconfig libraries

do_xtensa_dynconfig_get() { :; }
do_xtensa_dynconfig_extract() { :; }
do_xtensa_dynconfig_for_build() { :; }
do_xtensa_dynconfig_for_host() { :; }
do_xtensa_dynconfig_for_target() { :; }

if [ "${CT_XTENSA_DYNCONFIG}" = "y" ]; then

do_xtensa_dynconfig_for_build() {
    CT_DoStep INFO "Installing xtensa-dynconfig for build"

    CT_Pushd "${CT_XTENSA_DYNCONFIG_LOCATION}"
    CT_DoExecLog ALL make clean
    CT_DoLog EXTRA "Building xtensa-dynconfig"
    CT_DoExecLog ALL make CC=${CT_BUILD}-gcc CONF_DIR="${CT_XTENSA_DYNCONFIG_CONF_DIR}"
    CT_DoLog EXTRA "Installing xtensa-dynconfig"
    CT_DoExecLog ALL make install DESTDIR="${CT_BUILDTOOLS_PREFIX_DIR}/xtensa-dynconfig"
    CT_Popd

    CT_EndStep
}

do_xtensa_dynconfig_for_host() {
    CT_DoStep INFO "Installing xtensa-dynconfig for host"

    CT_Pushd "${CT_XTENSA_DYNCONFIG_LOCATION}"
    CT_DoExecLog ALL make clean
    CT_DoLog EXTRA "Building xtensa-dynconfig"
    CT_DoExecLog ALL make CC=${CT_HOST}-gcc CONF_DIR="${CT_XTENSA_DYNCONFIG_CONF_DIR}"
    CT_DoLog EXTRA "Installing xtensa-dynconfig"
    CT_DoExecLog ALL make install DESTDIR="${CT_PREFIX_DIR}"
    CT_Popd

    CT_EndStep
}
fi
