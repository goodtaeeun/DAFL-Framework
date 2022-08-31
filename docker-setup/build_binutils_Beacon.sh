#!/bin/bash
. $(dirname $0)/build_binutils_common.sh

# arg1 : cve number
function build_cxxfilt_for_Beacon() {
    mkdir outputs
    cd outputs
    target=$1

    /fuzzer/Beacon/precondInfer ../cxxfilt.bc --target-file=/benchmark/target/line/cxxfilt/$target --join-bound=5 >precond_log 2>&1
    /fuzzer/Beacon/Ins -output=../cxxfilt-$target.bc -byte -blocks=bbreaches__benchmark_target_line_cxxfilt_$target -afl -log=log.txt -load=./range_res.txt ./transed.bc

    clang ../cxxfilt-$target.bc -o ../cxxfilt-$target -lm -lz -ldl /fuzzer/Beacon/afl-llvm-rt.o

    cp ../cxxfilt-$target /benchmark/bin/Beacon/cxxfilt-$target
    cd ..
    rm -r outputs
}


prepare_code
# Build with Beacon
mkdir -p /benchmark/bin/Beacon

tar -xzf binutils-2.26.tar.gz
cd /benchmark/binutils-2.26

export PATH=/fuzzer/Beacon/clang+llvm/bin:$PATH
export PATH=/root/go/bin:$PATH
CC="gclang" CXX="gclang++" CFLAGS="-Wno-error -g" \
./configure || exit 1
make || exit 1

get-bc binutils/cxxfilt || exit 1

mkdir build
cp binutils/cxxfilt.bc build/
cd build


for cve in $CVE_LIST; do
    build_cxxfilt_for_Beacon $cve
done


rm -rf /benchmark/binutils-2.26

export PATH=/usr/local/bin:$PATH