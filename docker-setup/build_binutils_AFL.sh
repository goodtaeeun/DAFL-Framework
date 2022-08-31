#!/bin/bash

. $(dirname $0)/build_binutils_common.sh

prepare_code

# Build with AFL
mkdir -p /benchmark/bin/AFL
build_cxxfilt "/fuzzer/AFL/afl-clang-fast" "/fuzzer/AFL/afl-clang-fast++" "$ASAN_FLAGS"
for cve in $CVE_LIST; do
    cp binutils-2.26/binutils/cxxfilt /benchmark/bin/AFL/cxxfilt-$cve
done
rm -rf binutils-2.26
