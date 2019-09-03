

set -ex



test -f $PREFIX/lib/libXt.so
conda inspect linkages -p $PREFIX $PKG_NAME
exit 0
