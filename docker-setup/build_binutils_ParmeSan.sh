#!/bin/bash
. $(dirname $0)/build_binutils_common.sh

export PATH=/fuzzer/ParmeSan/clang+llvm/bin:$PATH

prepare_code
# Build with ParmeSan
mkdir -p /benchmark/bin/ParmeSan

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

mkdir in
echo " " > in/a.txt
python3 /fuzzer/ParmeSan/tools/compile_bc.py cxxfilt.bc
cd ../

cp /benchmark/binutils-2.26/binutils/build/cxxfilt* /benchmark/bin/ParmeSan/
rm -rf /benchmark/binutils-2.26

export PATH=/usr/local/bin:$PATH