#!/bin/bash

OPTS=""
if [[ $(uname) == Darwin ]]; then
  OPTS="--disable-openmp"
fi
if [ "${target_platform}" == linux-ppc64le ]; then
  OPTS="--disable-vmx "
fi

export CFLAGS="-fPIC ${CFLAGS}"

./configure --prefix=$PREFIX \
            --host=${HOST} \
            $OPTS

make -j${CPU_COUNT} ${VERBOSE_AT}
make check || { cat test/test-suite.log; exit 1; }
make install

# We can remove this when we start using the new conda-build.
find $PREFIX -name '*.la' -delete
