#!/bin/bash
set -euxo pipefail

## clone ParmeSan
git clone https://github.com/vusec/parmesan.git ParmeSan
cd /fuzzer/ParmeSan
git checkout fac580130146c07a2a0f82a24dfe0704e1851ab3

cd /
patch -p0 < /fuzzer/ParmeSan_compile_bc.py.patch
patch -p0 < /fuzzer/ParmeSan_angora_abilist.txt.patch
cd /fuzzer/ParmeSan

## install required llvm
LINUX_VER=${LINUX_VER:-ubuntu-16.04}
LLVM_VER=${LLVM_VER:-7.0.0}

LLVM_DEP_URL=https://releases.llvm.org/${LLVM_VER}
TAR_NAME=clang+llvm-${LLVM_VER}-x86_64-linux-gnu-${LINUX_VER}

wget ${LLVM_DEP_URL}/${TAR_NAME}.tar.xz || exit 1
tar -C /fuzzer/ParmeSan -xf ${TAR_NAME}.tar.xz
rm ${TAR_NAME}.tar.xz
mv /fuzzer/ParmeSan/${TAR_NAME} /fuzzer/ParmeSan/clang+llvm

## install required libraries
apt-get install -yy cargo libtinfo-dev

export LLVM_DIR=/fuzzer/ParmeSan/clang+llvm
export PATH=/fuzzer/ParmeSan/clang+llvm/bin:$PATH

## Build ParmeSan

if ! [ -x "$(command -v llvm-config)"  ]; then
    /fuzzer/ParmeSan/build/install_llvm.sh
    export PATH=${HOME}/clang+llvm/bin:$PATH
    export LD_LIBRARY_PATH=${HOME}/clang+llvm/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}
    export CC=clang
    export CXX=clang++
fi

cargo build
cargo build --release

rm -rf /fuzzer/ParmeSan/bin
mkdir -p /fuzzer/ParmeSan/bin
mkdir -p /fuzzer/ParmeSan/bin/lib
cp target/release/fuzzer /fuzzer/ParmeSan/bin/ || exit 1
cp target/release/*.a /fuzzer/ParmeSan/bin/lib/ || exit 1
cp target/release/log_reader /fuzzer/ParmeSan/bin/ || exit 1

cd llvm_mode
rm -rf build
mkdir -p build
cd build
cmake -DCMAKE_INSTALL_PREFIX=/fuzzer/ParmeSan/bin/ -DCMAKE_BUILD_TYPE=Release ..
make || exit 1 
make install || exit 1

#llvm-diff-parmesan
(cd /fuzzer/ParmeSan/tools/llvm-diff-parmesan && mkdir -p build && cd build && cmake .. && cmake --build . && cp llvm-diff-parmesan ../../../bin/) || exit 1
#id-assigner-standalone (HACK)
(cd /fuzzer/ParmeSan/tools/llvm-diff-parmesan && mkdir -p build-pass && cd build-pass && cmake -DBUILD_STANDALONE_PASS=1 ../id-assigner-pass && cmake --build . && cp src/*.so ../../../bin/pass/) || exit 1


## install wclang and gclang
pip3 install --upgrade pip==9.0.3
pip3 install wllvm
mkdir /root/go
go get github.com/SRI-CSL/gllvm/cmd/...

export PATH=/root/go/bin:$PATH
export PARMESAN_BASE=/fuzzer/ParmeSan
export LLVM_COMPILER=clang

export PATH=/usr/local/bin:$PATH
