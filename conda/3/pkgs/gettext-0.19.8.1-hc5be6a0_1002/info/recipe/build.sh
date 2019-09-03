#!/usr/bin/env bash

set -e

if [[ $(uname -o) == "Msys" ]] ; then
    export PREFIX="$LIBRARY_PREFIX_U"
    export PATH="$PATH_OVERRIDE"
    export BUILD=x86_64-pc-mingw64
    export HOST=x86_64-pc-mingw64

    # Setup needed for autoreconf. Keep am_version sync'ed with meta.yaml.

    am_version=1.15
    export ACLOCAL=aclocal-$am_version
    export AUTOMAKE=automake-$am_version

    # So, some autoconf checks depend on the C compiler name starting with
    # "cl" to detect that it's using MSVC. Inside `configure`, the CC variable
    # gets the path to the "compile" script prepended; this script translates
    # arguments. But the variable CXX does *not* get changed the same way, and
    # due to some flags added in gettext, the tests for a working C++ compiler
    # fail. So we have to manually specify that it should go through the
    # compile wrapper. Cf:
    # https://lists.gnu.org/archive/html/autoconf/2009-11/msg00016.html

    export CC="cl"
    export CXX="$(pwd)/build-aux/compile cl"
    export LD="link"
    export CPP="cl -nologo -E"
    export CXXCPP="cl -nologo -E"

    # Buuut we also need a custom wrapper for `cl -nologo -E` because the
    # invocation of the "windres"/"rc" tool can't handle preprocessor names
    # containing spaces. Windres also breaks if we don't use `--use-temp-file`
    # -- looks like the Cygwin popen() call might not work on Windows.

    export RC="windres --use-temp-file --preprocessor $RECIPE_DIR/msvcpp.sh"
    export WINDRES="windres --use-temp-file --preprocessor $RECIPE_DIR/msvcpp.sh"

    # We need to get the mingw stub libraries that let us link with system
    # DLLs. Stock gettext gets built on Windows so I'm not sure why it doesn't
    # have any needed Windows OS libraries specified anywhere, but it doesn't,
    # so we add them here too.

    export LDFLAGS="$LDFLAGS -L/mingw-w64/x86_64-w64-mingw32/lib -L$PREFIX/lib -ladvapi32"

    # /GL messes up Libtool's identification of how the linker works;
    # it parses dumpbin output and: https://stackoverflow.com/a/11850034/3760486

    export CFLAGS=$(echo " $CFLAGS " |sed -e "s, [-/]GL ,,")
    export CXXFLAGS=$(echo " $CXXFLAGS " |sed -e "s, [-/]GL ,,")

    autoreconf -vfi
fi

./configure --prefix=$PREFIX --build=$BUILD --host=$HOST
make -j${CPU_COUNT} ${VERBOSE_AT}
make install

# This overlaps with readline:
rm -rf ${PREFIX}/share/info/dir

find $PREFIX -name '*.la' -delete
