#!/bin/bash

. $(dirname $0)/build_bench_common.sh

# arg1 : Target project
# arg2 : Compiler to use for the final build.
# arg3 : Additional compiler options (e.g. LDFLAGS) for the final build.
# arg4 : Path to the bytecode
# arg5~: Fuzzing targets
function build_with_Beacon() {

    for TARG in "${@:5}"; do
        str_array=($TARG)
        BIN_NAME=${str_array[0]}
        
        arr=(${BIN_NAME//-/ })
        SIMPLE_BIN_NAME=${arr[0]}

        cd /benchmark
        CC="clang"
        CXX="clang++"
        ADDITIONAL="-flto -fuse-ld=gold -Wl,-plugin-opt=save-temps"
        build_target $1 $CC $CXX "$ADDITIONAL"

        cd RUNDIR-$1
        cp $4/$SIMPLE_BIN_NAME.0.0.preopt.bc $BIN_NAME.bc || exit 1
        
        if  [[ $SIMPLE_BIN_NAME == "cjpeg" ]]; then
            build_target $1 $CC $CXX " "
        fi

        for BUG_NAME in "${str_array[@]:1}"; do
            mkdir outputs
            cd outputs

            /fuzzer/Beacon/precondInfer ../$BIN_NAME.bc --target-file=/benchmark/target/line/$BIN_NAME/$BUG_NAME --join-bound=5 >precond_log 2>&1
            /fuzzer/Beacon/Ins -output=../$BIN_NAME-$BUG_NAME.bc -byte -blocks=bbreaches__benchmark_target_line_${BIN_NAME}_${BUG_NAME} -afl -log=log.txt -load=./range_res.txt ./transed.bc

            $2 ../$BIN_NAME-$BUG_NAME.bc -o ../$BIN_NAME-$BUG_NAME $3 /fuzzer/Beacon/afl-llvm-rt.o

            cp ../$BIN_NAME-$BUG_NAME /benchmark/bin/Beacon/$BIN_NAME-$BUG_NAME || exit 1
            cd ..
            rm -r outputs
        done
        cd ..
    done

    rm -rf RUNDIR-$1 || exit 1

}

export PATH=/fuzzer/Beacon/llvm4/bin:$PATH
export PATH=/fuzzer/Beacon/llvm4/lib:$PATH

# Build with Beacon
mkdir -p /benchmark/bin/Beacon
build_with_Beacon "libming-4.7" "clang" "-lm -lz" "BUILD/util" \
    "swftophp-4.7 2016-9827 2016-9829 2016-9831 2017-9988 2017-11728 2017-11729"
build_with_Beacon "libming-4.7.1" "clang" "-lm -lz" "BUILD/util" \
    "swftophp-4.7.1 2017-7578"
build_with_Beacon "libming-4.8" "clang" "-lm -lz" "BUILD/util" \
    "swftophp-4.8 2018-7868 2018-8807 2018-8962 2018-11095 2018-11225 2018-20427 2019-12982"
build_with_Beacon "libming-4.8.1" "clang" "-lm -lz" "BUILD/util" \
    "swftophp-4.8.1 2019-9114"
build_with_Beacon "lrzip-ed51e14" "clang++" "-lm -lz -lpthread -llzo2 -lbz2" "BUILD" \
    "lrzip-ed51e14 2018-11496"
build_with_Beacon "binutils-2.26" "clang" "-ldl" "binutils-2.26/binutils" \
    "cxxfilt 2016-4487 2016-4489 2016-4490 2016-4491 2016-4492 2016-6131"
build_with_Beacon "binutils-2.28" "clang" "-ldl" "binutils-2.28/binutils" \
    "objdump 2017-8392 2017-8396 2017-8397 2017-8398" \
    "objcopy 2017-8393 2017-8394 2017-8395"
build_with_Beacon "libpng-1.6.35" "clang" "-lm -lz" "libpng-1.6.35beta01" \
    "pngimage 2018-13785"
build_with_Beacon "libxml2-2.9.4" "clang" "-lm -lz" "libxml2-2.9.4" \
    "xmllint 2017-5969 2017-9047 2017-9048 2017-9049"
# For libjpeg, we should also pass .a file as input, too.
build_with_Beacon "libjpeg-1.5.90" "clang" "../RUNDIR-libjpeg-1.5.90/libjpeg-turbo-1.5.90/libjpeg.a" "libjpeg-turbo-1.5.90" \
    "cjpeg-1.5.90 2018-14498"
build_with_Beacon "libjpeg-2.0.4" "clang" "../RUNDIR-libjpeg-2.0.4/libjpeg-turbo-2.0.4/libjpeg.a" "libjpeg-turbo-2.0.4" \
    "cjpeg-2.0.4 2020-13790"
