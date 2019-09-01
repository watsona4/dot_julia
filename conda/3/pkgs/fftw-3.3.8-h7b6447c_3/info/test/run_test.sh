

set -ex



exit $(test -f ${PREFIX}/lib/libfftw3f.a)
exit $(test -f ${PREFIX}/lib/libfftw3.a)
exit $(test -f ${PREFIX}/lib/libfftw3l.a)
exit $(test -f ${PREFIX}/lib/libfftw3f_threads.a)
exit $(test -f ${PREFIX}/lib/libfftw3_threads.a)
exit $(test -f ${PREFIX}/lib/libfftw3l_threads.a)
test -f ${PREFIX}/include/fftw3.h
exit 0
