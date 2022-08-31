#!/bin/bash

. $(dirname $0)/build_binutils_common.sh

prepare_code

mkdir -p /benchmark/bin/AFLPP
mkdir -p /benchmark/bin/AFLPP-cmplog

# First, build without CMPLOG feature.
build_cxxfilt "/fuzzer/AFLPP/afl-clang-fast" "/fuzzer/AFLPP/afl-clang-fast++" "$ASAN_FLAGS"
for cve in $CVE_LIST; do
    cp binutils-2.26/binutils/cxxfilt /benchmark/bin/AFLPP/cxxfilt-$cve
done
rm -rf binutils-2.26

# Now, build with CMPLOG enabled.
export AFL_LLVM_CMPLOG=1
build_cxxfilt "/fuzzer/AFLPP/afl-clang-fast" "/fuzzer/AFLPP/afl-clang-fast++" "$ASAN_FLAGS"
for cve in $CVE_LIST; do
    cp binutils-2.26/binutils/cxxfilt /benchmark/bin/AFLPP-cmplog/cxxfilt-$cve
done
rm -rf binutils-2.26
unset AFL_LLVM_CMPLOG
