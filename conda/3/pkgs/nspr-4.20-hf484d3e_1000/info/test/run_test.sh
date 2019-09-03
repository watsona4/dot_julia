

set -ex



test -f ${PREFIX}/lib/libnspr4.a
test -f ${PREFIX}/lib/libnspr4${SHLIB_EXT}
test -f ${PREFIX}/lib/libplc4.a
test -f ${PREFIX}/lib/libplc4${SHLIB_EXT}
test -f ${PREFIX}/lib/libplds4.a
test -f ${PREFIX}/lib/libplds4${SHLIB_EXT}
exit 0
