# This file adds functions to build the Espressif binary wrappers

do_xtensa_esp_bin_wrappers_get() { :; }
do_xtensa_esp_bin_wrappers_extract() { :; }
do_xtensa_esp_bin_wrappers_for_build() { :; }
do_xtensa_esp_bin_wrappers_for_host() { :; }
do_xtensa_esp_bin_wrappers_for_target() { :; }

if [[ "${CT_TARGET_VENDOR}" = "esp" && -n "${CT_XTENSA_ESP_BIN_WRAPPERS_LOCATION}" ]]; then

map_triplet_to_rust() {
    local gcc_triplet="$1"

    case "$gcc_triplet" in
        x86_64*-linux-gnu)
            echo "x86_64-unknown-linux-gnu"
            ;;
        i586*-linux-gnu)
            echo "i586-unknown-linux-gnu"
            ;;
        i686*-linux-gnu)
            echo "i686-unknown-linux-gnu"
            ;;
        arm*-linux-gnueabi)
            echo "arm-unknown-linux-gnueabi"
            ;;
        arm*-linux-gnueabihf)
            echo "arm-unknown-linux-gnueabihf"
            ;;
        aarch64*-linux-gnu)
            echo "aarch64-unknown-linux-gnu"
            ;;
        aarch64*apple-darwin*)
            echo "aarch64-apple-darwin"
            ;;
        x86_64*apple-darwin*)
            echo "x86_64-apple-darwin"
            ;;
        i686*-mingw32)
            echo "i686-pc-windows-gnu"
            ;;
        x86_64*-mingw32)
            echo "x86_64-pc-windows-gnu"
            ;;
        *)
            echo "Unsupported"
            CT_DoLog ERROR ">> map_triplet_to_rust: unknown mapping for: $gcc_triplet"
            ;;
    esac
}

do_xtensa_esp_bin_wrappers_get() {
    CT_DoStep INFO "Installing rust for Espressif binary wrapper"

    export RUSTUP_HOME=${CT_BUILD_DIR}/rust/rustup
    export CARGO_HOME=${CT_BUILD_DIR}/rust/cargo
    RUST_VERSION=1.86.0

    CT_mkdir_pushd "${CT_BUILD_DIR}/rust"
    CT_DoExecLog ALL curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs -o rustup.sh
    CT_DoExecLog ALL chmod +x rustup.sh
    setarch ${CT_BUILD%%-*} ./rustup.sh -y \
        --no-modify-path \
        --default-toolchain "$RUST_VERSION" 2>&1
    CT_DoExecLog ALL ${CT_BUILD_DIR}/rust/cargo/bin/rustup target add $(map_triplet_to_rust ${CT_HOST})
    CT_DoExecLog ALL rm rustup.sh
    CT_Popd
    CT_EndStep
}

do_xtensa_esp_bin_wrappers_for_build () {
    CT_DoStep INFO "Building Espressif binary wrapper"

    export RUSTUP_HOME=${CT_BUILD_DIR}/rust/rustup
    export CARGO_HOME=${CT_BUILD_DIR}/rust/cargo
    export CARGO_NET_GIT_FETCH_WITH_CLI=true
    export CARGO_TARGET_DIR=${CT_BUILD_DIR}/esp_bin_wrapper

    rust_target=$(map_triplet_to_rust ${CT_HOST})

    CT_Pushd "${CT_XTENSA_ESP_BIN_WRAPPERS_LOCATION}"
    CT_DoExecLog ALL CT_DoExecLog ALL ${CT_BUILD_DIR}/rust/cargo/bin/cargo build --release --target=${rust_target} --config target.${rust_target}.linker=\"${CT_HOST}-gcc\"
    CT_Popd
}

do_xtensa_esp_bin_wrappers_for_target() {
    CT_DoStep INFO "Installing Espressif binary wrappers"

    rust_target=$(map_triplet_to_rust ${CT_HOST})
    ext=""
    if [[ "${rust_target}" == *windows* ]]; then
        ext=".exe"
    fi

    bin_wrapper=${CT_BUILD_DIR}/esp_bin_wrapper/${rust_target}/release/xtensa-toolchian-wrapper${ext}
    for file in ${CT_PREFIX_DIR}/bin/*; do
      filename=$(basename $file)
      for chip in esp32 esp32s2 esp32s3; do
        dst_file=${CT_PREFIX_DIR}/bin/${filename//esp/$chip}
        cp ${bin_wrapper} ${dst_file}
      done
    done

    CT_EndStep
}
fi
