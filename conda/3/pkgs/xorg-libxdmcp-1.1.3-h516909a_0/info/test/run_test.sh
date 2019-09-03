

set -ex



test -f $PREFIX/lib/libXdmcp.so
conda inspect linkages -p $PREFIX $PKG_NAME
exit 0
