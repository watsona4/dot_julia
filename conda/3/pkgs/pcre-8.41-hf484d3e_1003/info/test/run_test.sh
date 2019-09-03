

set -ex



pcre-config --version
pcregrep --help
pcretest --help
test -f "${PREFIX}/include/pcre.h"
test -f "${PREFIX}/include/pcre_scanner.h"
test -f "${PREFIX}/include/pcre_stringpiece.h"
test -f "${PREFIX}/include/pcrecpp.h"
test -f "${PREFIX}/include/pcrecpparg.h"
test -f "${PREFIX}/include/pcreposix.h"
test -f "${PREFIX}/lib/libpcre.a"
test -f "${PREFIX}/lib/libpcre${SHLIB_EXT}"
test -f "${PREFIX}/lib/libpcrecpp.a"
test -f "${PREFIX}/lib/libpcrecpp${SHLIB_EXT}"
test -f "${PREFIX}/lib/libpcreposix.a"
test -f "${PREFIX}/lib/libpcreposix${SHLIB_EXT}"
exit 0
