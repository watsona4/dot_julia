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
