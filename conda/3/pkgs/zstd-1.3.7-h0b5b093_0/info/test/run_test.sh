

set -ex



zstd -be -i5
test -f ${PREFIX}/include/zstd.h
test -f ${PREFIX}/lib/libzstd.a
test -f ${PREFIX}/lib/libzstd.so
pkg-config --cflags libzstd
exit 0
