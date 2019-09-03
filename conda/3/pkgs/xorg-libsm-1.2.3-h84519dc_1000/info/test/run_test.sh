

set -ex



test -f $PREFIX/lib/libSM.so
conda inspect linkages -p $PREFIX $PKG_NAME
exit 0
