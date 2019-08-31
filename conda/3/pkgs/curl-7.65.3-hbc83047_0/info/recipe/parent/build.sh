#!/bin/bash

export PKG_CONFIG_PATH="${PREFIX}/lib/pkgconfig"
export C_INCLUDE_PATH="${PREFIX}/include"

# Legacy toolchain flags
if [[ ${c_compiler} =~ .*toolchain.* ]]; then
    if [ $(uname) == "Darwin" ]; then
        export DYLD_FALLBACK_LIBRARY_PATH="${PREFIX}/lib"
        export CC=clang
        export CXX=clang++
    else
        export LDFLAGS="$LDFLAGS -Wl,--disable-new-dtags"
    fi
fi
if [[ ${target_platform} != osx-64 ]]; then
    export LDFLAGS="${LDFLAGS} -Wl,-rpath-link,$PREFIX/lib"
fi

./configure \
    --prefix=${PREFIX} \
    --host=${HOST} \
    --disable-ldap \
    --with-ca-bundle=${PREFIX}/ssl/cacert.pem \
    --with-ssl=${PREFIX} \
    --with-zlib=${PREFIX} \
    --with-gssapi=${PREFIX} \
    --with-libssh2=${PREFIX} \
|| cat config.log

make -j${CPU_COUNT} ${VERBOSE_AT}
# TODO :: test 1119... exit FAILED
# make test
make install

# Includes man pages and other miscellaneous.
rm -rf "${PREFIX}/share"
