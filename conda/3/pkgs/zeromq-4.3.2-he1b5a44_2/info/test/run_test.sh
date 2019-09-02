

set -ex



test -f ${PREFIX}/lib/libzmq.a
test -f ${PREFIX}/lib/libzmq.so
test -f ${PREFIX}/lib/libzmq.so.5
ldd ${PREFIX}/lib/libzmq.so | grep sodium
test -f ${PREFIX}/lib/cmake/ZeroMQ/ZeroMQConfig.cmake
test -f ${PREFIX}/lib/cmake/ZeroMQ/ZeroMQConfigVersion.cmake
${PREFIX}/bin/curve_keygen
exit 0
