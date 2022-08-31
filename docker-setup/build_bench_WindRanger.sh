#!/bin/bash

. $(dirname $0)/build_bench_common.sh
set -x
# arg1 : Target project
# arg2 : Compiler to use for the final build.
# arg3 : Additional compiler options (e.g. LDFLAGS) for the final build.
# arg4~: fuzzing target string
function build_with_WindRanger() {

    for TARG in "${@:4}"; do
        str_array=($TARG)
        BIN_NAME=${str_array[0]}

        arr=(${BIN_NAME//-/ })
        SIMPLE_BIN_NAME=${arr[0]}

        cd /benchmark
        CC="gclang"
        CXX="gclang++"
        build_target $1 $CC $CXX ""

        cd RUNDIR-$1
        get-bc $BIN_NAME || exit 1

        if  [[ $SIMPLE_BIN_NAME == "cjpeg" ]]; then
            build_target $1 $CC $CXX " "
        fi

        for BUG_NAME in "${str_array[@]:1}"; do
            mkdir output
            cd output
            cp ../$BIN_NAME.bc ./
            /fuzzer/WindRanger/instrument/bin/cbi --targets=/benchmark/target/line/$BIN_NAME/$BUG_NAME ./$BIN_NAME.bc
            $2 ./$BIN_NAME.ci.bc $3 -o ./$BIN_NAME-$BUG_NAME

            cp ./$BIN_NAME-$BUG_NAME /benchmark/bin/WindRanger/$BIN_NAME-$BUG_NAME || exit 1
            cp ./distance.txt /benchmark/bin/WindRanger/$BIN_NAME-$BUG_NAME-distance.txt
            cp ./targets.txt /benchmark/bin/WindRanger/$BIN_NAME-$BUG_NAME-targets.txt
            cp ./condition_info.txt /benchmark/bin/WindRanger/$BIN_NAME-$BUG_NAME-condition_info.txt
        done
        cd ..
        rm -r output
    done

    rm -rf RUNDIR-$1 || exit 1

}

export PATH=/fuzzer/WindRanger/clang+llvm/bin:$PATH
export PATH=/root/go/bin:$PATH

# Build with Beacon
mkdir -p /benchmark/bin/WindRanger
build_with_WindRanger "libming-4.7" "/fuzzer/WindRanger/fuzz/afl-clang-fast" "-lm -lz" \
    "swftophp-4.7 2016-9827 2016-9829 2016-9831 2017-9988 2017-11728 2017-11729"
build_with_WindRanger "libming-4.7.1" "/fuzzer/WindRanger/fuzz/afl-clang-fast" "-lm -lz" \
    "swftophp-4.7.1 2017-7578"
build_with_WindRanger "libming-4.8" "/fuzzer/WindRanger/fuzz/afl-clang-fast" "-lm -lz" \
    "swftophp-4.8 2018-7868 2018-8807 2018-8962 2018-11095 2018-11225 2018-20427 2019-12982"
build_with_WindRanger "libming-4.8.1" "/fuzzer/WindRanger/fuzz/afl-clang-fast" "-lm -lz" \
    "swftophp-4.8.1 2019-9114"
build_with_WindRanger "lrzip-ed51e14" "/fuzzer/WindRanger/fuzz/afl-clang-fast++" "-lm -lz -lpthread -llzo2 -lbz2" \
    "lrzip-ed51e14 2018-11496"
build_with_WindRanger "binutils-2.26" "/fuzzer/WindRanger/fuzz/afl-clang-fast" "-ldl" \
    "cxxfilt 2016-4487 2016-4489 2016-4490 2016-4491 2016-4492 2016-6131"
build_with_WindRanger "binutils-2.28" "/fuzzer/WindRanger/fuzz/afl-clang-fast" "-ldl" \
    "objdump 2017-8392 2017-8396 2017-8397 2017-8398" \
    "objcopy 2017-8393 2017-8394 2017-8395"
build_with_WindRanger "libpng-1.6.35" "/fuzzer/WindRanger/fuzz/afl-clang-fast" "-lm -lz" \
    "pngimage 2018-13785"
build_with_WindRanger "libxml2-2.9.4" "/fuzzer/WindRanger/fuzz/afl-clang-fast" "-lm -lz" \
    "xmllint 2017-5969 2017-9047 2017-9048 2017-9049"
# For libjpeg, we should also pass .a file as input, too.
build_with_WindRanger "libjpeg-1.5.90" "/fuzzer/WindRanger/fuzz/afl-clang-fast" "../RUNDIR-libjpeg-1.5.90/libjpeg-turbo-1.5.90/libjpeg.a" \
    "cjpeg-1.5.90 2018-14498"
build_with_WindRanger "libjpeg-2.0.4" "/fuzzer/WindRanger/fuzz/afl-clang-fast" "../RUNDIR-libjpeg-2.0.4/libjpeg-turbo-2.0.4/libjpeg.a" \
    "cjpeg-2.0.4 2020-13790"
