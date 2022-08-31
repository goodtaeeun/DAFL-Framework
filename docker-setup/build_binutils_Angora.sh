#!/bin/bash
. $(dirname $0)/build_binutils_common.sh

export PATH=/fuzzer/Angora/clang+llvm/bin:$PATH

prepare_code
# Build with Angora
mkdir -p /benchmark/bin/Angora

tar -xzf binutils-2.26.tar.gz
cd /benchmark/binutils-2.26

export PATH=/root/go/bin:$PATH
CC="gclang" CXX="gclang++" CFLAGS="-Wno-error -fPIC" \
./configure --with-pic || exit 1
make || exit 1

cd binutils
get-bc cxxfilt || exit 1

mkdir build
cp cxxfilt.bc build/
cd build

USE_TRACK=1 /fuzzer/Angora/bin/angora-clang -Wno-error -fPIC -o cxxfilt.track cxxfilt.bc || exit 1
USE_FAST=1 /fuzzer/Angora/bin/angora-clang -Wno-error -fPIC -fsanitize=address -o cxxfilt.fast cxxfilt.bc || exit 1 

rm cxxfilt.bc

cp /benchmark/binutils-2.26/binutils/build/cxxfilt* /benchmark/bin/Angora/
rm -rf /benchmark/binutils-2.26

export PATH=/usr/local/bin:$PATH