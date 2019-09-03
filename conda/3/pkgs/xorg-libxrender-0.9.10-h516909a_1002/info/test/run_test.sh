

set -ex



test -f $PREFIX/lib/libXrender.so
conda inspect linkages -p $PREFIX $PKG_NAME
exit 0
