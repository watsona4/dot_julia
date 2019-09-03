#!/bin/bash

bash configure --prefix=$PREFIX --disable-all-programs --enable-libuuid

make
make tests
make install

rm -fr $PREFIX/share
