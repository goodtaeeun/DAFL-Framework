#!/bin/bash

. $(dirname $0)/build_binutils_common.sh

prepare_code

# Build with DAFL
mkdir -p /benchmark/build_log
mkdir -p /benchmark/bin/DAFL
CC="/fuzzer/DAFL/afl-clang-fast"
CXX="/fuzzer/DAFL/afl-clang-fast++"
for cve in $CVE_LIST; do
    export DAFL_SELECTIVE_COV="/benchmark/DAFL-input/inst-targ/cxxfilt/$cve"
    export DAFL_DFG_SCORE="/benchmark/DAFL-input/dfg/cxxfilt/$cve"
    build_cxxfilt $CC $CXX "$ASAN_FLAGS" 2>&1 \
      | tee /benchmark/build_log/$cve.txt
    cp binutils-2.26/binutils/cxxfilt /benchmark/bin/DAFL/cxxfilt-$cve
    rm -rf binutils-2.26
done
unset DAFL_SELECTIVE_COV
unset DAFL_DFG_SCORE
