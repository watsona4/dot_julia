#!/bin/bash

# As of Mac OS 10.8, X11 is no longer included by default
# (See https://support.apple.com/en-us/HT201341 for the details).
# Due to this change, we disable building X11 support for cairo on OS X by
# default.

if [ $(uname) == Darwin ]; then
    XWIN_ARGS="--disable-xlib --disable-xcb --disable-glitz"
fi
if [ $(uname) == Linux ]; then
    XWIN_ARGS="--enable-xcb-shm"
fi
if [ $(uname -m) == x86_64 ]; then
    export ax_cv_c_float_words_bigendian="no"
fi
bash autogen.sh

# Cf. https://github.com/conda-forge/staged-recipes/issues/673, we're in the
# process of excising Libtool files from our packages. Existing ones can break
# the build while this happens.
find $PREFIX -name '*.la' -delete
./configure \
    --prefix="${PREFIX}" \
    --enable-warnings \
    --enable-ft \
    --enable-ps \
    --enable-pdf \
    --enable-svg \
    --disable-gtk-doc \
    $XWIN_ARGS

make -j${CPU_COUNT}
# FAIL: check-link on OS X
# Hangs for > 10 minutes on Linux
#make check -j${CPU_COUNT}
make install -j${CPU_COUNT}

# Remove any new Libtool files we may have installed. It is intended that
# conda-build will eventually do this automatically.
find $PREFIX -name '*.la' -delete
