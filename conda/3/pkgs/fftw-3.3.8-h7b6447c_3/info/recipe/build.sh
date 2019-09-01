#!/usr/bin/env bash

export LDFLAGS="${LDFLAGS} -L${PREFIX}/lib"
export CFLAGS="${CFLAGS} -I${PREFIX}/include -O3 -fomit-frame-pointer -fstrict-aliasing -ffast-math"

CONFIGURE="./configure --prefix=$PREFIX --with-pic --enable-shared --enable-threads --disable-fortran"

# (Note exported LDFLAGS and CFLAGS vars provided above.)
BUILD_CMD="make -j${CPU_COUNT}"
INSTALL_CMD="make install"

# Test suite
# tests are performed during building as they are not available in the
# installed package.
# Additional tests can be run with "make smallcheck" and "make bigcheck"
TEST_CMD="eval cd tests && make check-local && cd -"

#
# We build 3 different versions of fftw:
#
if [[ "$target_platform" == "linux-64" ]] || [[ "$target_platform" == "linux-32" ]] || [[ "$target_platform" == "osx-64" ]]; then
  ARCH_OPTS_SINGLE="--enable-sse --enable-sse2 --enable-avx"
  ARCH_OPTS_DOUBLE="--enable-sse2 --enable-avx"
  ARCH_OPTS_LONG_DOUBLE="--enable-long-double"
fi

build_cases=(
    # single
    "$CONFIGURE --enable-float ${ARCH_OPTS_SINGLE}"
    # double
    "$CONFIGURE ${ARCH_OPTS_DOUBLE}"
    # long double (SSE2 and AVX not supported)
    "$CONFIGURE ${ARCH_OPTS_LONG_DOUBLE}"
)

for config in "${build_cases[@]}"
do
    :
    $config
    ${BUILD_CMD}
    ${INSTALL_CMD}
    ${TEST_CMD}
done

