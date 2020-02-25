#!/bin/sh

#TODO Make a chinese profile with mirrors
#GITLAB_SSH_SERVER=
#MIRROR_BASE=
#MIRROR_PATH=
#git config submodule.overlays.url $GITLAB_SSH_SERVER/...

SCRIPT_DIR=$(readlink -f $(dirname -- "${0}"))

# a base path for GCC, newlib, gdb GITs...
LOCAL_REPOS=$(readlink -f "$PWD/..")

CONF_TARGET="xtensa-esp32s3-elf"

if [ ! -x ./ct-ng ]; then
    git submodule update --init

    ./bootstrap
    ./configure --enable-local
    make
fi

./ct-ng ${CONF_TARGET}

#
# Main projects references
#

echo "CT_NEWLIB_DEVEL_URL=\"${LOCAL_REPOS}/newlib-cygwin\"" >> .config
echo "CT_NEWLIB_DEVEL_BRANCH=\"feature/esp32s3_1\"" >> .config

#echo "CT_GCC_DEVEL_URL=\"${LOCAL_REPOS}/gcc\"" >> .config
#echo "CT_GCC_DEVEL_BRANCH=\"multilib1\"" >> .config

#echo "CT_BINUTILS_DEVEL_URL=\"${LOCAL_REPOS}/binutils\"" >> .config
#echo "CT_BINUTILS_DEVEL_BRANCH=\"multilib1\"" >> .config

#echo "CT_GDB_DEVEL_URL=\"${LOCAL_REPOS}/binutils\"" >> .config
#echo "CT_GDB_DEVEL_BRANCH=\"esp-binutils-gdb\"" >> .config
# Disable GDB for fast building
#echo "# CT_DEBUG_GDB is not set" >> .config

#
# Some options for in-place building
#

echo "# CT_LOG_PROGRESS_BAR is not set" >> .config
echo "# CT_PREFIX_DIR_RO is not set" >> .config
echo "CT_LOG_EXTRA=y" >> .config
echo "CT_LOG_LEVEL_MAX=\"EXTRA\"" >> .config

echo "# CT_COMP_LIBS_EXPAT is not set" >> .config
echo "# CT_COMP_LIBS_NCURSES is not set" >> .config

echo "# CT_CC_GCC_USE_GRAPHITE is not set" >> .config
echo "# CT_CC_GCC_USE_LTO is not set" >> .config
echo "# CT_COMP_LIBS_ISL is not set" >> .config

echo "CT_CONNECT_TIMEOUT=30" >> .config

echo "CT_ALLOW_BUILD_AS_ROOT=y" >> .config
echo "CT_ALLOW_BUILD_AS_ROOT_SURE=y" >> .config

if [ ! -d .build/tarballs/ ]; then
    mkdir -p .build/tarballs/
    cp ${SCRIPT_DIR}/tarballs/* .build/tarballs/
fi

./ct-ng oldconfig

# WE CANNOT USE LD_LIBRARY_PATH when crosstoll is building
#if [ -d ${LOCAL_REPOS}/gcc-xtensa-dynconfig-plugin ]; then
#	export LD_LIBRARY_PATH=${LOCAL_REPOS}/gcc-xtensa-dynconfig-plugin:$LD_LIBRARY_PATH
#fi
#echo $LD_LIBRARY_PATH

./ct-ng build

#TODO Make a 'create a distribution archive' option
