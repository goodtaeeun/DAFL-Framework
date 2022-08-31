#!/bin/bash

. $(dirname $0)/build_binutils_common.sh

prepare_code

# Build with DAFL, only with DFG-based scheduling enabled.
mkdir -p /benchmark/bin/DAFL-schedule
CC="/fuzzer/DAFL/afl-clang-fast"
CXX="/fuzzer/DAFL/afl-clang-fast++"
unset DAFL_SELECTIVE_COV
for cve in $CVE_LIST; do
    export DAFL_DFG_SCORE="/benchmark/DAFL-input/dfg/cxxfilt/$cve"
    build_cxxfilt $CC $CXX "$ASAN_FLAGS"
    cp binutils-2.26/binutils/cxxfilt /benchmark/bin/DAFL-schedule/cxxfilt-$cve
    rm -rf binutils-2.26
done
unset DAFL_DFG_SCORE
