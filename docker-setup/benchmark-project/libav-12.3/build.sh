#!/bin/bash

URL="https://github.com/libav/libav/archive/refs/tags/v12.3.zip"
DIRNAME="libav-12.3"
ARCHIVE=$DIRNAME".zip"

wget $URL -O $ARCHIVE
rm -rf $DIRNAME
unzip $ARCHIVE || exit 1
cd $DIRNAME
./configure || exit 1
make || exit 1
cd ../
cp $DIRNAME/avconv ./avconv || exit 1
