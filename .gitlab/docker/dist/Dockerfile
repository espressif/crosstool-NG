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

WORKDIR /opt
COPY dist.tar.xz /opt/
RUN tar -xf dist.tar.xz && rm -v dist.tar.xz && ls -l /opt/*
ENV PATH=/opt/riscv64-esp-linux-gnu/bin:$PATH

ENV CROSS_COMPILE=riscv64-esp-linux-gnu-
ENV ARCH=riscv
