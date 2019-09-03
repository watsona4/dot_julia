

set -ex



test -f ${PREFIX}/lib/libuuid.a
conda inspect linkages libuuid
exit 0
