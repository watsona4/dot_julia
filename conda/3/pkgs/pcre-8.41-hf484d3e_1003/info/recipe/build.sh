#!/bin/bash

./configure --prefix="${PREFIX}"  \
            --host="${HOST}"      \
            --enable-utf          \
            --enable-unicode-properties
make -j${CPU_COUNT} ${VERBOSE_AT}
make check
make install

# Delete man pages.
rm -rf "${PREFIX}/share"

# We can remove this when we start using the new conda-build.
find $PREFIX -name '*.la' -delete
