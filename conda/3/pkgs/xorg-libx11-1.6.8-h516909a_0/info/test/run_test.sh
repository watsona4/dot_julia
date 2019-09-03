

set -ex



test -f $PREFIX/lib/libX11.so
test -f $PREFIX/lib/libX11-xcb.so
conda inspect linkages -p $PREFIX $PKG_NAME
exit 0
