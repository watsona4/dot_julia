

set -ex



test -f ${PREFIX}/lib/libnspr4${SHLIB_EXT}
test -f ${PREFIX}/lib/libplds4${SHLIB_EXT}
test -f ${PREFIX}/lib/libplc4${SHLIB_EXT}
test -f ${PREFIX}/lib/libsoftokn3${SHLIB_EXT}
test -f ${PREFIX}/lib/libsoftokn3.chk
test -f ${PREFIX}/lib/libnss3${SHLIB_EXT}
test -f ${PREFIX}/lib/libsmime3${SHLIB_EXT}
test -f ${PREFIX}/lib/libssl3${SHLIB_EXT}
test -f ${PREFIX}/lib/libnssckbi${SHLIB_EXT}
exit 0
