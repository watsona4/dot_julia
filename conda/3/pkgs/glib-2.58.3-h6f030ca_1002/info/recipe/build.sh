#!/usr/bin/env bash

set -ex

if [[ $(uname) = Darwin ]] ; then
    # Meson automatically adds the necessary rpath arguments on macOS, but the
    # current version has a bug which causes a build failure if the argument
    # is duplicated in $LDFLAGS. (It's fixed in 0.49.). So, strip that out.
    export LDFLAGS="$(echo $LDFLAGS |sed -e "s| -Wl,-rpath,$PREFIX/lib||")"
fi

# @PYTHON@ is used in the build scripts and that breaks with the long prefix.
# we need to redefine that to `python`.
_PY=$PYTHON
export PYTHON="python"

mkdir forgebuild
cd forgebuild
meson --buildtype=release --prefix="$PREFIX" --backend=ninja -Dlibdir=lib \
      -Diconv=gnu -Dlibmount=false -Dselinux=false -Dxattr=false ..
ninja -j${CPU_COUNT} -v

if [ "${target_platform}" == 'linux-aarch64' ] || [ "${target_platform}" == "linux-ppc64le" ]; then
    export MESON_TEST_TIMEOUT_MULTIPLIER=16
else
    export MESON_TEST_TIMEOUT_MULTIPLIER=2
fi

if [[ $(uname) != Darwin ]] ; then  # too many tests fail on macOS
    meson test --no-suite flaky --timeout-multiplier ${MESON_TEST_TIMEOUT_MULTIPLIER}
fi

ninja install

export PYTHON=$_PY

# remove libtool files
find $PREFIX -name '*.la' -delete

# gdb folder has a nested folder structure similar to our host prefix
# (255 chars) which causes installation issues so remove it.
rm -rf $PREFIX/share/gdb
