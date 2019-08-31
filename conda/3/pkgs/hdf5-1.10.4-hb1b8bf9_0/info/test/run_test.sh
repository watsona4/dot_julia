# Stop on first error
set -e

# Ping @msarahan: This is causing me trouble due to Apple not having released the source
# for the latest ld64 yet. Is there any way to have stuff from the build matrix used in
# the test phase?
export CONDA_BUILD_SYSROOT=/opt/MacOSX10.9.sdk

# Test C compiler
echo "Testing h5cc"
h5cc -show
h5cc h5_cmprss.c -o h5_cmprss
./h5_cmprss

# Test C++ compiler
echo "Testing h5c++"
h5c++ -show
h5c++ h5tutr_cmprss.cpp -o h5tutr_cmprss
./h5tutr_cmprss

# Test Fortran 90 compiler
echo "Testing h5fc"
h5fc -show
h5fc h5_cmprss.f90 -o h5_cmprss
./h5_cmprss

# Test Fortran 2003 compiler, note that the file has a 90 extension
echo "Testing h5fc for Fortran 2003"
h5fc compound_fortran2003.f90 -o compound_fortran2003
./compound_fortran2003


set -ex



command -v h5c++
command -v h5cc
command -v h5perf_serial
command -v h5redeploy
command -v h5fc
command -v gif2h5
command -v h52gif
command -v h5copy
command -v h5debug
command -v h5diff
command -v h5dump
command -v h5import
command -v h5jam
command -v h5ls
command -v h5mkgrp
command -v h5repack
command -v h5repart
command -v h5stat
command -v h5unjam
test -f $PREFIX/lib/libhdf5.a
test -f $PREFIX/lib/libhdf5.so
test -f $PREFIX/lib/libhdf5_cpp.a
test -f $PREFIX/lib/libhdf5_cpp.so
test -f $PREFIX/lib/libhdf5_hl.a
test -f $PREFIX/lib/libhdf5_hl.so
test -f $PREFIX/lib/libhdf5_hl_cpp.a
test -f $PREFIX/lib/libhdf5_hl_cpp.so
exit 0
