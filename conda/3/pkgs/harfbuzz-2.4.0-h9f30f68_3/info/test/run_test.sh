

set -ex



test -f $PREFIX/lib/libharfbuzz-icu.so
test -f $PREFIX/lib/libharfbuzz.so
test -f $PREFIX/include/harfbuzz/hb-ft.h
hb-view --version
conda inspect linkages -p $PREFIX $PKG_NAME
exit 0
