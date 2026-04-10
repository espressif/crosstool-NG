FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
  apt-get install -y --no-install-recommends \
    apt-utils \
    autoconf \
    bzip2 \
    ca-certificates \
    cmake \
    curl \
    dejagnu \
    expect \
    git \
    iproute2 \
    iputils-ping \
    less \
    lzip \
    lzma \
    make \
    openssh-client \
    patch \
    python3 \
    qemu-user \
    texinfo \
    timelimit \
    unzip \
    wget \
    xz-utils \
    zip \
  && rm -rf /var/lib/apt/lists/*
