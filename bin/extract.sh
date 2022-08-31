#!/bin/bash

if [[ $1 == "binutils-2.26" ]]; then
  mkdir -p /RUNDIR-$1/BUILD/sparrow  
  cd /benchmark
  tar -xzf binutils-2.26.tar.gz
  cd binutils-2.26
  CC=clang CFLAGS="-Wno-error=unused-command-line-argument \
                -Wno-error=null-pointer-arithmetic \
                -Wno-error=pointer-compare \
                -g -fsanitize=address" ./configure
  make clean
  /smake/smake --init
  CC=clang ASAN_OPTIONS=detect_leaks=0 /smake/smake -j
  cp ./sparrow/binutils/cxxfilt/* /RUNDIR-$1/BUILD/sparrow/
  exit 0
else
  CMAKE_EXPORT_COMPILE_COMMANDS=1 /benchmark/fuzzer-test-suite/build-target.sh $1
fi

cd /RUNDIR-$1

if [[ $1 == "vorbis-2017-12-11" ]]; then
  cd BUILD
  cd ogg
  make clean
  yes | /smake/smake --init
  /smake/smake -j

  cd ../vorbis
  make clean
  yes | /smake/smake --init
  /smake/smake -j
elif [[ $1 == "lcms-2017-03-21" ]]; then
  cd BUILD
  make clean
  yes | /smake/smake --init
  /smake/smake -j
elif [[ $1 == "boringssl-2016-02-12" ]]; then
  cd BUILD
  /smake/scmake
elif [[ $1 == "libarchive-2017-01-04" ]]; then
  cd BUILD
  make clean
  yes | /smake/smake --init
  /smake/smake -j
elif [[ $1 == "libxml2-v2.9.2" ]]; then
  cd BUILD
  make clean
  yes | /smake/smake --init
  /smake/smake -j
elif [[ $1 == "openssl-1.0.2d" ]]; then
  cd BUILD
  make clean
  yes | /smake/smake --init
  /smake/smake -j 1
elif [[ $1 == "sqlite-2016-11-14" ]]; then
  mkdir -p BUILD/sparrow
  cp ../benchmark/fuzzer-test-suite/sqlite-2016-11-14/* ./BUILD/
  cd BUILD
  clang -E -o sqlite3.i sqlite3.c
  clang -E -o ossfuzz.i -I../ ossfuzz.c
elif [[ $1 == "c-ares-CVE-2016-5180" ]]; then
  cd BUILD
  make clean
  yes | /smake/smake --init
  /smake/smake -j 1
elif [[ $1 == "freetype2-2017" ]]; then
  cd BUILD
  make clean
  yes | /smake/smake --init
  /smake/smake -j 1
elif [[ $1 == "libssh-2017-1272" ]]; then
  cd BUILD/build
  /smake/scmake
elif [[ $1 == "openssl-1.0.1f" ]]; then
  cd BUILD
  make clean
  yes | /smake/smake --init
  /smake/smake -j 1


else
  echo "Not supported"
fi
