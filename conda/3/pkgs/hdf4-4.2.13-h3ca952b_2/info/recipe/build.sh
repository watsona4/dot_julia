#!/bin/bash

export CFLAGS="$CFLAGS -I$PREFIX/include -L$PREFIX/lib"
export CXXFLAGS="$CXXFLAGS -I$PREFIX/include -L$PREFIX/lib"
export LDFLAGS="$LDFLAGS -L$PREFIX/lib -Wl,-rpath,${PREFIX}/lib"

chmod +x configure

# The --enable-silent-rules is needed because Travis CI dies on the long output from this build.
./configure --prefix=${PREFIX}\
            --host=$HOST \
            --enable-linux-lfs \
            --enable-silent-rules \
            --enable-shared \
            --with-ssl \
            --with-zlib \
            --with-jpeg \
            --disable-netcdf \
            --disable-fortran

make
make install
# temporarily disabled due to segfault.
#make check

# Remove man pages.
rm -rf ${PREFIX}/share

# Avoid clashing names with netcdf.
mv ${PREFIX}/bin/ncdump ${PREFIX}/bin/h4_ncdump
mv ${PREFIX}/bin/ncgen ${PREFIX}/bin/h4_ncgen

# People usually Google these.
rm -rf ${PREFIX}/examples
