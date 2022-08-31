#!/bin/bash

. $(dirname $0)/build_binutils_common.sh

# TODO: Refactor using build_cxxfilt().
# arg1 : cve number
function build_cxxfilt_with_AFLGo() {
    tar -xzf binutils-2.26.tar.gz
    cd binutils-2.26
    mkdir -p obj-aflgo/temp
    SUBJECT=$PWD
    TMP_DIR=$PWD/obj-aflgo/temp
    cp /benchmark/target/stack-trace/cxxfilt/$1 $TMP_DIR/BBtargets.txt
    ADDITIONAL="-targets=$TMP_DIR/BBtargets.txt \
                -outdir=$TMP_DIR -flto -fuse-ld=gold \
                -Wl,-plugin-opt=save-temps"

    cd obj-aflgo
    CC=/fuzzer/AFLGo/afl-clang-fast CXX=/fuzzer/AFLGo/afl-clang-fast++ \
    CFLAGS="$DEFAULT_CFLAGS $ADDITIONAL" \
    LDFLAGS="-ldl -lutil" \
    ../configure $CONFIG_OPTIONS
    make clean; make
    cat $TMP_DIR/BBnames.txt | rev | cut -d: -f2- | rev | sort | uniq > $TMP_DIR/BBnames2.txt \
    && mv $TMP_DIR/BBnames2.txt $TMP_DIR/BBnames.txt
    cat $TMP_DIR/BBcalls.txt | sort | uniq > $TMP_DIR/BBcalls2.txt \
    && mv $TMP_DIR/BBcalls2.txt $TMP_DIR/BBcalls.txt

    cd binutils
    /fuzzer/AFLGo/scripts/genDistance.sh $PWD $TMP_DIR cxxfilt
    cd ../../
    mkdir obj-dist
    cd obj-dist # work around because cannot run make distclean
    CC=/fuzzer/AFLGo/afl-clang-fast CXX=/fuzzer/AFLGo/afl-clang-fast++ \
    CFLAGS="$DEFAULT_CFLAGS $ASAN_FLAGS -distance=$TMP_DIR/distance.cfg.txt" \
    LDFLAGS="-ldl -lutil" \
    ../configure $CONFIG_OPTIONS
    make
    cd ../../
}


prepare_code

# Build with AFLGo
mkdir -p /benchmark/bin/AFLGo
for cve in $CVE_LIST; do
    build_cxxfilt_with_AFLGo $cve
    cp binutils-2.26/obj-dist/binutils/cxxfilt /benchmark/bin/AFLGo/cxxfilt-$cve
    rm -rf binutils-2.26
done
