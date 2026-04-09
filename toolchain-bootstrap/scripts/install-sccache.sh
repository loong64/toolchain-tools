#!/bin/bash

set -euo errexit -o pipefail

org=mozilla
libc=musl

if [ $(uname -m) = "x86_64" ]; then
  arch=x86_64
  sha256=8424b38cda4ecce616a1557d81328f3d7c96503a171eab79942fad618b42af44
elif [ $(uname -m) = "aarch64" ]; then
  arch=aarch64
  sha256=62a6c942c47c93333bc0174704800cef7edfa0416d08e1356c1d3e39f0b462f2
elif [ $(uname -m) = "loongarch64" ]; then
  org=loong64
  libc=gnu
  arch=loongarch64
  sha256=484ce01b34ead27dd4078fb4198c9d8fc732f7a61129631b476c3718592c734d
fi

secure-download.sh \
  https://github.com/${org}/sccache/releases/download/v0.14.0/sccache-v0.14.0-${arch}-unknown-linux-${libc}.tar.gz \
  ${sha256} \
  sccache.tar.gz

tar --strip-components=1 -xvf sccache.tar.gz
chmod +x sccache
mv sccache /usr/local/bin
rm -rf sccache*