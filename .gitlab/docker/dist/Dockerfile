FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
  apt-get install -y --no-install-recommends \
    bzip2 \
    ca-certificates \
    cmake \
    git \
    make \
    unzip \
    wget \
    xz-utils \
  && rm -rf /var/lib/apt/lists/*

ARG TARGET="riscv64-esp-linux-musl"

COPY "${TARGET}/" "/opt/${TARGET}/"
ENV PATH=/opt/${TARGET}/bin:$PATH

ENV CROSS_COMPILE="${TARGET}-"
ENV ARCH=riscv
