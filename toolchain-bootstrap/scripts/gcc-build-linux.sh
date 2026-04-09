#!/usr/bin/env bash
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

set -o errexit
set -o pipefail
set -x

if [ -e /build/secrets ]; then
  source /build/secrets
fi

cd /build

export PATH=/toolchain/bin:$PATH

curl -sSLO https://github.com/cgitmirror/config/raw/refs/heads/master/config.guess
curl -sSLO https://github.com/cgitmirror/config/raw/refs/heads/master/config.sub

mkdir gcc
pushd gcc
tar --strip-components=1 -xf ../gcc-${GCC_VERSION}.tar.xz

mkdir gmp
pushd gmp
tar --strip-components=1 -xf ../../gmp-${GMP_VERSION}.tar.xz
cp -f /build/config.guess /build/config.sub .
popd

mkdir isl
pushd isl
tar --strip-components=1 -xf ../../isl-${ISL_VERSION}.tar.bz2
cp -f /build/config.guess /build/config.sub .
popd

mkdir mpc
pushd mpc
tar --strip-components=1 -xf ../../mpc-${MPC_VERSION}.tar.gz
cp -f /build/config.guess /build/config.sub build-aux/
popd

mkdir mpfr
pushd mpfr
tar --strip-components=1 -xf ../../mpfr-${MPFR_VERSION}.tar.bz2
cp -f /build/config.guess /build/config.sub .
popd

popd

mkdir gcc-objdir
pushd gcc-objdir

if [ "$(uname -m)" = "x86_64" ]; then
  triple="x86_64-linux-gnu"
  configureextra="--enable-multiarch --with-arch-32=i686 --with-abi=m64 --enable-multilib --with-multilib-list=m32,m64 --with-tune=generic"
  libdirs="lib32 lib64"
elif [ "$(uname -m)" = "aarch64" ]; then
  triple="aarch64-linux-gnu"
  configureextra="--enable-multiarch"
  libdirs="lib64"
elif [ "$(uname -m)" = "loongarch64" ]; then
  triple="loongarch64-linux-gnu"
  libdirs="lib64"
fi

# --enable-gold=default --enable-ld installs gold as ld.gold and ld and ld as ld.bfd.
CC="sccache ${BUILD_CC}" \
CXX="sccache ${BUILD_CXX}" \
    ../gcc/configure \
    --host=${triple} \
    --prefix=/toolchain \
    --enable-ld \
    --disable-gnu-unique-object \
    --enable-__cxa_atexit \
    --enable-linker-build-id \
    --enable-plugin \
    --enable-default-pie \
    --enable-languages=c,c++ \
    --with-gcc-major-version-only \
    ${configureextra} ${EXTRA_CONFIGURE_ARGS}

time make -j ${PARALLEL}
## error: cannot execute 'cc1': posix_spawnp: Permission denied
# time make -j ${PARALLEL} STAGE_CC_WRAPPER=sccache-wrapper.sh
time make -j ${PARALLEL} install DESTDIR=/build/out-install

# Copy the toolchain support files to its own output tree so they can be operated
# on in isolation.
mkdir -p /build/out-support/lib
cp -a /build/out-install/toolchain/include /build/out-support/
cp -a /build/out-install/toolchain/lib/gcc /build/out-support/lib/
for lib in ${libdirs}; do
    cp -a /build/out-install/toolchain/${lib} /build/out-support/
done

popd

# Free up gigabytes.
rm -rf gcc gcc-objdir

sccache -s
