

set -ex



test -f $PREFIX/lib/libXau.so
conda inspect linkages -p $PREFIX $PKG_NAME
exit 0
