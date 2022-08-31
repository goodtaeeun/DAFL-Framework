#!/bin/bash

URL="https://github.com/glennrp/libpng/archive/refs/tags/v1.6.35beta01.zip"
DIRNAME="libpng-1.6.35beta01"
ARCHIVE=$DIRNAME".zip"

wget $URL -O $ARCHIVE
rm -rf $DIRNAME
unzip $ARCHIVE || exit 1
cd $DIRNAME
# Referred to the original CVE report in the sourceforge repository.
sed -i 's/return ((int)(crc != png_ptr->crc));/return (0);/g' pngrutil.c
autoreconf -f -i
./configure --disable-shared || exit 1
make all || exit 1
cd ../
cp $DIRNAME/pngimage ./ || exit 1
