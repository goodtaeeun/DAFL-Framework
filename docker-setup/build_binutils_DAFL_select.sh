#!/bin/bash

. $(dirname $0)/build_binutils_common.sh

prepare_code

# Build with DAFL, only with selective coverage feedback enabled.
mkdir -p /benchmark/bin/DAFL-select
CC="/fuzzer/DAFL/afl-clang-fast"
CXX="/fuzzer/DAFL/afl-clang-fast++"
unset DAFL_DFG_SCORE
for cve in $CVE_LIST; do
    export DAFL_SELECTIVE_COV="/benchmark/DAFL-input/inst-targ/cxxfilt/$cve"
    build_cxxfilt $CC $CXX "$ASAN_FLAGS"
    cp binutils-2.26/binutils/cxxfilt /benchmark/bin/DAFL-select/cxxfilt-$cve
    rm -rf binutils-2.26
done
unset DAFL_SELECTIVE_COV
