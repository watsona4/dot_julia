

set -ex



test -f ${PREFIX}/include/lzo/lzoconf.h
test -f ${PREFIX}/lib/liblzo2.a
test -f ${PREFIX}/lib/liblzo2.so
conda inspect linkages -p $PREFIX lzo
exit 0
