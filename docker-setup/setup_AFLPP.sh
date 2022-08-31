#!/bin/bash
wget https://github.com/AFLplusplus/AFLplusplus/archive/refs/tags/3.14c.tar.gz || exit 1
tar -xzf 3.14c.tar.gz
mv AFLplusplus-3.14c AFLPP
cd AFLPP && make
