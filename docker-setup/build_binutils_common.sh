#!/bin/bash

CVE_LIST="2016-4487 2016-4489 2016-4490 2016-4491 2016-4492 2016-6131"
DEFAULT_CFLAGS="-DFORTIFY_SOURCE=2 -fstack-protector-all \
                -fno-omit-frame-pointer -g -Wno-error"
CONFIG_OPTIONS="--disable-shared --disable-gdb \
                 --disable-libdecnumber --disable-readline \
                 --disable-sim --disable-ld"
ASAN_FLAGS="-fsanitize=address"

# arg1 : string for CC
# arg2 : string for CXX
# arg3 : additional string for CFLAGS (optional)
function build_cxxfilt() {
    tar -xzf binutils-2.26.tar.gz
    cd binutils-2.26
    CC=$1 CXX=$2 CFLAGS="$DEFAULT_CFLAGS $3" \
    ./configure $CONFIG_OPTIONS || exit 1
    make || exit 1
    cd ../
}

# Common setup
function prepare_code() {
    if [[ ! -f binutils-2.26.tar.gz ]]; then
        wget http://ftp.gnu.org/gnu/binutils/binutils-2.26.tar.gz || exit 1
    fi
}
