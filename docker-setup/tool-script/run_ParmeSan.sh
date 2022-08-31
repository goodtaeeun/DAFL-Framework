#!/bin/bash

FUZZER_NAME='ParmeSan'
. $(dirname $0)/common-setup.sh

mkdir seed
cp /benchmark/seed/empty ./seed/input.txt

cp /benchmark/ParmeSan-input/$1 ./targets.pruned.json
cp /benchmark/bin/ParmeSan/* ./
cp /benchmark/bin/AFL/cxxfilt-2016-4487 ./$1

export ANGORA_DISABLE_CPU_BINDING=1

timeout $4 /fuzzer/ParmeSan/bin/fuzzer \
-c ./targets.pruned.json -i seed -o output -t ./cxxfilt.track -s ./cxxfilt.san.fast -- ./cxxfilt.fast

. $(dirname $0)/common-postproc.sh
