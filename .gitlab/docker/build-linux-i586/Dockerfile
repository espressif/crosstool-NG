FROM i386/debian:bullseye

ARG DEBIAN_FRONTEND=noninteractive

RUN sed -i \
    -e '/bullseye-security/d' \
    -e '/bullseye-updates/d' \
    -e 's|deb.debian.org/debian|archive.debian.org/debian|g' \
    /etc/apt/sources.list \
  && apt-get -o Acquire::Check-Valid-Until=false update \
  && apt-get install -y --allow-downgrades --no-install-recommends \
    autoconf \
    automake \
    bison \
    bzip2 \
    ca-certificates \
    curl \
    flex \
    g++ \
    gawk \
    gcc \
    git \
    gperf \
    help2man \
    libc6=2.31-13+deb11u11 \
    libc-dev-bin=2.31-13+deb11u11 \
    libc6-dev=2.31-13+deb11u11 \
    libncurses5-dev \
    libstdc++6 \
    libtool \
    libtool-bin \
    make \
    meson \
    ninja-build \
    patch \
    perl=5.32.1-4+deb11u3 \
    perl-base=5.32.1-4+deb11u3 \
    python3-dev \
    rsync \
    texinfo \
    unzip \
    wget \
    xz-utils \
  && rm -rf /var/lib/apt/lists/*
