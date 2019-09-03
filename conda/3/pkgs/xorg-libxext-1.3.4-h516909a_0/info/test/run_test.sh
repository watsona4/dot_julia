

set -ex



test -f $PREFIX/lib/libXext.so
conda inspect linkages -p $PREFIX $PKG_NAME
exit 0
