

set -ex



hdiff -V
h4_ncgen -V
h4_ncdump -V
test -f ${PREFIX}/lib/libdf.a
test -f ${PREFIX}/lib/libmfhdf.a
test -f ${PREFIX}/lib/libdf.so
test -f ${PREFIX}/lib/libmfhdf.so
exit 0
