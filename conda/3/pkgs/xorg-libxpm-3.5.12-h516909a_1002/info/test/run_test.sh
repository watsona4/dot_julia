

set -ex



test -f $PREFIX/lib/libXpm.so
conda inspect linkages -p $PREFIX $PKG_NAME
exit 0
