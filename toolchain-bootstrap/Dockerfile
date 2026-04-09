ARG BASE_IMAGE=trixie

# ghcr.io/loong64/debian:trixie
FROM ghcr.io/loong64/debian:trixie AS trixie

ENV HOME=/build \
    SHELL=/bin/bash \
    USER=build \
    LOGNAME=build \
    HOSTNAME=builder \
    DEBIAN_FRONTEND=noninteractive
CMD ["/bin/bash", "--login"]
WORKDIR '/build'

ADD scripts/secure-download.sh /usr/local/bin/
ADD scripts/install-sccache.sh /usr/local/bin/
ADD scripts/sccache-wrapper.sh /usr/local/bin/

RUN <<EOF
#!/bin/bash
set -euo pipefail

groupadd -g 1000 build
useradd -u 1000 -g 1000 -d /build -s /bin/bash -m build
chown -R build:build /build /etc/ld.so.conf.d /usr/local

( echo 'quiet "true";';
  echo 'APT::Get::Assume-Yes "true";';
  echo 'APT::Install-Recommends "false";';
  echo 'Acquire::Check-Valid-Until "false";';
  echo 'Acquire::Retries "5";';
) > /etc/apt/apt.conf.d/99portable-clang

apt-get update
apt-get install --force-yes ca-certificates curl
install-sccache.sh
EOF

FROM ${BASE_IMAGE} AS gnu-build
RUN <<EOF
apt-get install --force-yes autoconf automake bison build-essential gawk libtool gcc make texinfo xz-utils unzip
if [ $(uname -m) = "x86_64" ]; then
  apt-get install --force-yes gcc-multilib
fi
EOF
USER build:build

FROM gnu-build AS gcc-12
ARG PARALLEL=16
ARG GCC_VERSION=12.4.0
ARG GCC_SHA256=704f652604ccbccb14bdabf3478c9511c89788b12cb3bbffded37341916a9175
ARG GMP_VERSION=6.2.1
ARG GMP_SHA256=fd4829912cddd12f84181c3451cc752be224643e87fac497b69edddadc49b4f2
ARG ISL_VERSION=0.24
ARG ISL_SHA256=fcf78dd9656c10eb8cf9fbd5f59a0b6b01386205fe1934b3b287a0a1898145c0
ARG MPC_VERSION=1.2.1
ARG MPC_SHA256=17503d2c395dfcf106b622dc142683c1199431d095367c6aacba6eec30340459
ARG MPFR_VERSION=4.1.0
ARG MPFR_SHA256=feced2d430dd5a97805fa289fed3fc8ff2b094c02d05287fd6133e7f1f0ec926

ADD --link --checksum=sha256:${GCC_SHA256} --chmod=644 https://mirrors.ocf.berkeley.edu/gnu/gcc/gcc-${GCC_VERSION}/gcc-${GCC_VERSION}.tar.xz gcc-12.tar.xz
ADD --link --checksum=sha256:${GMP_SHA256} --chmod=644 https://mirrors.ocf.berkeley.edu/gnu/gmp/gmp-${GMP_VERSION}.tar.xz gmp-6.2.tar.xz
ADD --link --checksum=sha256:${ISL_SHA256} --chmod=644 https://gcc.gnu.org/pub/gcc/infrastructure/isl-${ISL_VERSION}.tar.bz2 isl-0.24.tar.bz2
ADD --link --checksum=sha256:${MPC_SHA256} --chmod=644 https://gcc.gnu.org/pub/gcc/infrastructure/mpc-${MPC_VERSION}.tar.gz mpc-1.2.tar.gz
ADD --link --checksum=sha256:${MPFR_SHA256} --chmod=644 https://gcc.gnu.org/pub/gcc/infrastructure/mpfr-${MPFR_VERSION}.tar.bz2 mpfr-4.1.tar.bz2
COPY --link scripts/gcc-build-linux.sh /build/gcc-build.sh
RUN --mount=type=secret,id=secrets,target=/build/secrets,uid=1000 \
    GCC_VERSION=12 GMP_VERSION=6.2 ISL_VERSION=0.24 MPC_VERSION=1.2 MPFR_VERSION=4.1 \
    BUILD_CC=/usr/bin/gcc BUILD_CXX=/usr/bin/g++ \
    EXTRA_CONFIGURE_ARGS=--disable-bootstrap \
    PARALLEL=${PARALLEL} \
    /build/gcc-build.sh

# We need to build binutils with a modern GCC to avoid a relocation error with
# old binutils from base image. And modern GCC is required for binutils >2.41.
FROM gnu-build AS binutils
ARG BINUTILS_VERSION=2.46
ARG BINUTILS_SHA256=a389850c2d3919f2cc96fb8b5e7711eacfc819259aaffb11615c9fb9756eaeae

ADD --link --checksum=sha256:${BINUTILS_SHA256} --chmod=644 https://mirrors.ocf.berkeley.edu/gnu/binutils/binutils-with-gold-${BINUTILS_VERSION}.tar.xz binutils.tar.xz
COPY --from=gcc-12 --link /build/out-install/toolchain /toolchain/
COPY --link scripts/binutils-build.sh /build/binutils-build.sh
RUN --mount=type=secret,id=secrets,target=/build/secrets,uid=1000 \
    BUILD_CC=/toolchain/bin/gcc \
    BUILD_CXX=/toolchain/bin/g++ \
    EXTRA_CONFIGURE_ARGS=--enable-bootstrap \
    /build/binutils-build.sh

FROM gnu-build AS gcc-15
ARG PARALLEL=16
ARG GCC_VERSION=15.2.0
ARG GCC_SHA256=438fd996826b0c82485a29da03a72d71d6e3541a83ec702df4271f6fe025d24e
ARG GMP_VERSION=6.2.1
ARG GMP_SHA256=fd4829912cddd12f84181c3451cc752be224643e87fac497b69edddadc49b4f2
ARG ISL_VERSION=0.24
ARG ISL_SHA256=fcf78dd9656c10eb8cf9fbd5f59a0b6b01386205fe1934b3b287a0a1898145c0
ARG MPC_VERSION=1.2.1
ARG MPC_SHA256=17503d2c395dfcf106b622dc142683c1199431d095367c6aacba6eec30340459
ARG MPFR_VERSION=4.1.0
ARG MPFR_SHA256=feced2d430dd5a97805fa289fed3fc8ff2b094c02d05287fd6133e7f1f0ec926

ADD --link --checksum=sha256:${GCC_SHA256} --chmod=644 https://mirrors.ocf.berkeley.edu/gnu/gcc/gcc-${GCC_VERSION}/gcc-${GCC_VERSION}.tar.xz gcc-15.tar.xz
ADD --link --checksum=sha256:${GMP_SHA256} --chmod=644 https://mirrors.ocf.berkeley.edu/gnu/gmp/gmp-${GMP_VERSION}.tar.xz gmp-6.2.tar.xz
ADD --link --checksum=sha256:${ISL_SHA256} --chmod=644 https://gcc.gnu.org/pub/gcc/infrastructure/isl-${ISL_VERSION}.tar.bz2 isl-0.24.tar.bz2
ADD --link --checksum=sha256:${MPC_SHA256} --chmod=644 https://gcc.gnu.org/pub/gcc/infrastructure/mpc-${MPC_VERSION}.tar.gz mpc-1.2.tar.gz
ADD --link --checksum=sha256:${MPFR_SHA256} --chmod=644 https://gcc.gnu.org/pub/gcc/infrastructure/mpfr-${MPFR_VERSION}.tar.bz2 mpfr-4.1.tar.bz2
COPY --from=binutils --link /build/out/toolchain /toolchain/
COPY --from=gcc-12 --link /build/out-install/toolchain /toolchain/
COPY --link scripts/gcc-build-linux.sh /build/gcc-build.sh
RUN --mount=type=secret,id=secrets,target=/build/secrets,uid=1000 \
    GCC_VERSION=15 GMP_VERSION=6.2 ISL_VERSION=0.24 MPC_VERSION=1.2 MPFR_VERSION=4.1 \
    BUILD_CC=/toolchain/bin/gcc \
    BUILD_CXX=/toolchain/bin/g++ \
    PARALLEL=${PARALLEL} \
    /build/gcc-build.sh

FROM ${BASE_IMAGE} AS openssl
ARG PARALLEL=16
ARG OPENSSL_VERSION=3.0.19
ARG OPENSSL_SHA256=fa5a4143b8aae18be53ef2f3caf29a2e0747430b8bc74d32d88335b94ab63072
RUN apt-get install --force-yes build-essential
ADD --link --checksum=sha256:${OPENSSL_SHA256} --chmod=644 https://github.com/openssl/openssl/releases/download/openssl-${OPENSSL_VERSION}/openssl-${OPENSSL_VERSION}.tar.gz openssl.tar.gz
COPY --from=binutils --link /build/out/toolchain /toolchain/
COPY --from=gcc-12 --link /build/out-install/toolchain /toolchain/
COPY --link scripts/openssl-build.sh /build/
RUN PARALLEL=${PARALLEL} /build/openssl-build.sh

FROM ${BASE_IMAGE} AS zstd
ARG PARALLEL=16
ARG ZSTD_VERSION=1.5.7
ARG ZSTD_SHA256=eb33e51f49a15e023950cd7825ca74a4a2b43db8354825ac24fc1b7ee09e6fa3
RUN apt-get install --force-yes build-essential
ADD --link --checksum=sha256:${ZSTD_SHA256} https://github.com/facebook/zstd/releases/download/v${ZSTD_VERSION}/zstd-${ZSTD_VERSION}.tar.gz zstd.tar.gz
COPY --from=binutils --link /build/out/toolchain /toolchain/
COPY --from=gcc-12 --link /build/out-install/toolchain /toolchain/
COPY --link scripts/zstd-build.sh /build/zstd-build.sh
RUN PARALLEL=${PARALLEL} /build/zstd-build.sh

FROM ${BASE_IMAGE} AS cpython
ARG PARALLEL=16
ARG PYTHON_VERSION=3.13.12
ARG PYTHON_SHA256=2a84cd31dd8d8ea8aaff75de66fc1b4b0127dd5799aa50a64ae9a313885b4593
ADD --link --checksum=sha256:${PYTHON_SHA256} https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tar.xz cpython.tar.xz
RUN apt-get install --force-yes autoconf automake build-essential libffi-dev make tar xz-utils zlib1g-dev
COPY --from=binutils --link /build/out/toolchain /toolchain/
COPY --from=openssl --link /build/out/toolchain /toolchain/
COPY --from=gcc-12 --link /build/out-install/toolchain /toolchain/
COPY --link scripts/cpython-build.sh /build/
RUN --mount=type=secret,id=secrets,target=/build/secrets,uid=1000 \
    PARALLEL=${PARALLEL} /build/cpython-build.sh

FROM scratch AS download-llvm
ARG LLVM_VERSION=22.1.3
ARG LLVM_SHA256=2488c33a959eafba1c44f253e5bbe7ac958eb53fa626298a3a5f4b87373767cd
ADD --link --checksum=sha256:${LLVM_SHA256} https://github.com/llvm/llvm-project/releases/download/llvmorg-${LLVM_VERSION}/llvm-project-${LLVM_VERSION}.src.tar.xz /llvm.tar.xz

FROM scratch AS download-cmake-aarch64
ARG CMAKE_VERSION=3.31.11
ARG CMAKE_SHA256=faef5420c3853d0e10a3862a0d3c71b40ffc2de36fc0ef0bcc5c896cf18f240f
ADD --link --checksum=sha256:${CMAKE_SHA256} https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-linux-aarch64.tar.gz /cmake.tar.gz

FROM scratch AS download-cmake-loongarch64
ARG CMAKE_VERSION=3.31.11
ARG CMAKE_SHA256=0a14a0ff2b9d4cf5a117325061c21154bd679aeb48e4cb9c7c3a546729fc09de
ADD --link --checksum=sha256:${CMAKE_SHA256} https://github.com/loong64/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-linux-loongarch64.tar.gz /cmake.tar.gz

FROM scratch AS download-cmake-x86_64
ARG CMAKE_VERSION=3.31.11
ARG CMAKE_SHA256=d815c10cf54e8e122088b3bb25ea6b4010fb96b7ad6e1ad3fdef75be3d996b0b
ADD --link --checksum=sha256:${CMAKE_SHA256} https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-linux-x86_64.tar.gz /cmake.tar.gz

FROM ${BASE_IMAGE} AS download-cmake
COPY --from=download-cmake-aarch64 --link /cmake.tar.gz /cmake.aarch64.tar.gz
COPY --from=download-cmake-loongarch64 --link /cmake.tar.gz /cmake.loongarch64.tar.gz
COPY --from=download-cmake-x86_64 --link /cmake.tar.gz /cmake.x86_64.tar.gz
RUN <<EOF
if [ $(uname -m) = "x86_64" ]; then
  cp /cmake.x86_64.tar.gz /cmake.tar.gz
elif [ $(uname -m) = "aarch64" ]; then
  cp /cmake.aarch64.tar.gz /cmake.tar.gz
elif [ $(uname -m) = "loongarch64" ]; then
  cp /cmake.loongarch64.tar.gz /cmake.tar.gz
fi
EOF

FROM scratch AS download-ninja-aarch64
ARG NINJA_VERSION=1.13.2
ARG NINJA_SHA256=fd2cacc8050a7f12a16a2e48f9e06fca5c14fc4c2bee2babb67b58be17a607fc
ADD --link --checksum=sha256:${NINJA_SHA256} https://github.com/ninja-build/ninja/releases/download/v${NINJA_VERSION}/ninja-linux-aarch64.zip /ninja.zip

FROM scratch AS download-ninja-loongarch64
ARG NINJA_VERSION=1.13.2
ARG NINJA_SHA256=3a088172958e391dfa41b937bcede32dd9f99ad3f1ae8fd3de492c8c3f6f1700
ADD --link --checksum=sha256:${NINJA_SHA256} https://github.com/loong64/ninja/releases/download/v${NINJA_VERSION}/ninja-linux-loongarch64.zip /ninja.zip

FROM scratch AS download-ninja-x86_64
# Upgrading to 1.13.x introduces libstdc++ ABI issues:
# /usr/local/bin/ninja: /usr/lib/x86_64-linux-gnu/libstdc++.so.6: version `CXXABI_1.3.9' not found (required by /usr/local/bin/ninja)
ARG NINJA_VERSION=1.12.1
ARG NINJA_SHA256=6f98805688d19672bd699fbbfa2c2cf0fc054ac3df1f0e6a47664d963d530255
ADD --link --checksum=sha256:${NINJA_SHA256} https://github.com/ninja-build/ninja/releases/download/v${NINJA_VERSION}/ninja-linux.zip /ninja.zip

FROM ${BASE_IMAGE} AS download-ninja
COPY --from=download-ninja-aarch64 /ninja.zip /ninja.aarch64.zip
COPY --from=download-ninja-loongarch64 /ninja.zip /ninja.loongarch64.zip
COPY --from=download-ninja-x86_64 /ninja.zip /ninja.x86_64.zip
RUN <<EOF
if [ $(uname -m) = "x86_64" ]; then
  cp /ninja.x86_64.zip /ninja.zip
elif [ $(uname -m) = "aarch64" ]; then
  cp /ninja.aarch64.zip /ninja.zip
elif [ $(uname -m) = "loongarch64" ]; then
  cp /ninja.loongarch64.zip /ninja.zip
fi
EOF

FROM ${BASE_IMAGE} AS clang-bootstrap
ARG PARALLEL_NINJA=64
ARG NINJA_MAX_LOAD=32

RUN <<EOF
apt-get install --force-yes libc6-dev patch tar xz-utils unzip zlib1g-dev
if [ $(uname -m) = "x86_64" ]; then
  apt-get install --force-yes libc6-dev:i386
fi
EOF
COPY --from=download-cmake --link /cmake.tar.gz cmake.tar.gz
COPY --from=download-ninja --link /ninja.zip ninja.zip
COPY --from=download-llvm --link /llvm.tar.xz llvm.tar.xz
COPY --from=binutils --link /build/out/toolchain /toolchain/
COPY --from=gcc-15 --link /build/out-install/toolchain /toolchain/
COPY --from=cpython --link /build/out/toolchain /toolchain/
COPY --link scripts/clang-bootstrap.sh /build/
RUN --mount=type=secret,id=secrets,target=/build/secrets,uid=1000 \
    PARALLEL_NINJA=${PARALLEL_NINJA} NINJA_MAX_LOAD=${NINJA_MAX_LOAD} \
    /build/clang-bootstrap.sh

FROM ${BASE_IMAGE} AS llvm-gnu-linux
ARG PARALLEL_NINJA=64
ARG NINJA_MAX_LOAD=32

# We need compiler-rt to find the libc statically linked object files (like crt1.o)
# for i386. Getting this to work reliably is finicky. Using a multiarch system
# with the multiarch install of i386 makes this "just work."
RUN <<EOF
apt-get install --force-yes libc6-dev patch tar xz-utils unzip zlib1g-dev
if [ $(uname -m) = "x86_64" ]; then
  apt-get install --force-yes libc6-dev:i386
fi
EOF
COPY --from=download-cmake --link /cmake.tar.gz cmake.tar.gz
COPY --from=download-ninja --link /ninja.zip ninja.zip
COPY --from=download-llvm --link /llvm.tar.xz llvm.tar.xz
COPY --from=binutils --link /build/out/toolchain /toolchain/
COPY --from=gcc-15 --link /build/out-support/ /toolchain/
COPY --from=cpython --link /build/out/toolchain /toolchain/
COPY --from=clang-bootstrap --link /build/out/toolchain /toolchain/
COPY --from=zstd --link /build/out/toolchain /toolchain/
COPY --link scripts/clang-gnu-stage2.sh /build/
RUN --mount=type=secret,id=secrets,target=/build/secrets,uid=1000 \
     PARALLEL_NINJA=${PARALLEL_NINJA} NINJA_MAX_LOAD=${NINJA_MAX_LOAD} \
    /build/clang-gnu-stage2.sh

FROM trixie AS llvm-gnu-linux-loongarch64
RUN apt-get install tar zstd
COPY --from=gcc-15 --link /build/out-support /build/gcc-support/
COPY --from=llvm-gnu-linux --link /build/out/toolchain/ /build/llvm/
COPY --link scripts/llvm-assemble-toolchain.sh /build/
ARG SOURCE_DATE_EPOCH
RUN <<EOF
if [ $(uname -m) = "x86_64" ]; then
  GNU_TARGET=x86_64-linux-gnu
elif [ $(uname -m) = "aarch64" ]; then
  GNU_TARGET=aarch64-linux-gnu
elif [ $(uname -m) = "loongarch64" ]; then
  GNU_TARGET=loongarch64-linux-gnu
fi

GNU_TARGET=${GNU_TARGET} GCC_VERSION=15 /build/llvm-assemble-toolchain.sh
EOF
