

set -ex



test -f $PREFIX/lib/libICE.so
conda inspect linkages -p $PREFIX $PKG_NAME
exit 0
