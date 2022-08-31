#!/bin/bash
set -x

## clone Angora
git clone https://github.com/AngoraFuzzer/Angora.git
cd /fuzzer/Angora
git checkout 6b46c8553970a71de42c0d274d166876ef478b51

cd /
patch -p0 < /fuzzer/Angora_angora_abilist.txt.patch
cd /fuzzer/Angora

## install required llvm
LINUX_VER=${LINUX_VER:-ubuntu-20.04}
LLVM_VER=${LLVM_VER:-11.0.0}

LLVM_DEP_URL=https://github.com/llvm/llvm-project/releases
TAR_NAME=clang+llvm-${LLVM_VER}-x86_64-linux-gnu-${LINUX_VER}

wget -q ${LLVM_DEP_URL}/download/llvmorg-${LLVM_VER}/${TAR_NAME}.tar.xz || exit 1
tar -C /fuzzer/Angora -xf ${TAR_NAME}.tar.xz
rm ${TAR_NAME}.tar.xz
mv /fuzzer/Angora/${TAR_NAME} /fuzzer/Angora/clang+llvm

## install required libraries
apt-get install -yy cargo libtinfo-dev

export LLVM_DIR=/fuzzer/Angora/clang+llvm
export PATH=/fuzzer/Angora/clang+llvm/bin:$PATH

## Build Angora

if ! [ -x "$(command -v llvm-config)"  ]; then
    /fuzzer/Angora/build/install_llvm.sh
    export PATH=${HOME}/clang+llvm/bin:$PATH
    export LD_LIBRARY_PATH=${HOME}/clang+llvm/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}
    export CC=clang
    export CXX=clang++
fi

cargo build
cargo build --release

rm -rf /fuzzer/Angora/bin
mkdir -p /fuzzer/Angora/bin
mkdir -p /fuzzer/Angora/bin/lib
cp target/release/fuzzer /fuzzer/Angora/bin/ || exit 1
cp target/release/*.a /fuzzer/Angora/bin/lib/ || exit 1

cd llvm_mode
rm -rf build
mkdir -p build
cd build
cmake -DCMAKE_INSTALL_PREFIX=/fuzzer/Angora/bin/ -DCMAKE_BUILD_TYPE=Release ..
make 
make install || exit 1



## install wclang and gclang
pip3 install --upgrade pip==9.0.3
pip3 install wllvm
mkdir /root/go
go get github.com/SRI-CSL/gllvm/cmd/...

export PATH=/root/go/bin:$PATH
export ANGORA_BASE=/fuzzer/Angora
export LLVM_COMPILER=clang

export PATH=/usr/local/bin:$PATH
