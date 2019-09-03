#!/bin/bash

set -e

if [ $(uname) == Darwin ]; then
  export CC=clang
  export CXX=clang++
  export MACOSX_DEPLOYMENT_TARGET="10.9"
  export CXXFLAGS="-stdlib=libc++ $CXXFLAGS"
  export LDFLAGS="$LDFLAGS -Wl,-rpath,$PREFIX/lib"
fi

# Cf. https://github.com/conda-forge/staged-recipes/issues/673, we're in the
# process of excising Libtool files from our packages. Existing ones can break
# the build while this happens.
find $PREFIX -name '*.la' -delete

# CircleCI seems to have some weird issue with harfbuzz tarballs. The files
# come out with modification times such that the build scripts want to rerun
# automake, etc.; we need to run it ourselves since we don't have the precise
# version that the build scripts embed. And the 'configure' script comes out
# without its execute bit set. In a Docker container running locally, these
# problems don't occur.

autoreconf --force --install -I $PREFIX/share/aclocal
chmod +x configure

./configure --prefix=$PREFIX \
            --disable-gtk-doc \
            --enable-static \
            --with-graphite2=yes \
            --with-gobject=yes

make
# FIXME
# OS X:
# FAIL: test-ot-tag
# Linux (all the tests pass when using the docker image :-/)
# FAIL: check-c-linkage-decls.sh
# FAIL: check-defs.sh
# FAIL: check-header-guards.sh
# FAIL: check-includes.sh
# FAIL: check-libstdc++.sh
# FAIL: check-static-inits.sh
# FAIL: check-symbols.sh
# PASS: test-ot-tag
# make check
make install

# Remove any new Libtool files we may have installed. It is intended that
# conda-build will eventually do this automatically.
find $PREFIX -name '*.la' -delete

pushd $PREFIX
rm -rf share/gtk-doc
popd
