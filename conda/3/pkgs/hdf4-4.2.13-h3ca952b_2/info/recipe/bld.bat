set LIB=%LIBRARY_LIB%;%LIB%
set LIBPATH=%LIBRARY_LIB%;%LIBPATH%
set INCLUDE=%LIBRARY_INC%;%INCLUDE%;%RECIPE_DIR%

mkdir build_dir
cd build_dir

:: Configure step.
cmake -G "%CMAKE_GENERATOR%" ^
      -D CMAKE_BUILD_TYPE=Release ^
      :: -D HDF4_BUILD_HL_LIB=ON ^
      -D CMAKE_PREFIX_PATH=%LIBRARY_PREFIX% ^
      -D ZLIB_DIR=%LIBRARY_PREFIX% ^
      -D JPEG_DIR=%LIBRARY_PREFIX% ^
      -D HDF4_BUILD_FORTRAN=NO ^
      -D HDF4_ENABLE_NETCDF=NO ^
      -D BUILD_SHARED_LIBS:BOOL=ON ^
      -D CMAKE_INSTALL_PREFIX:PATH=%LIBRARY_PREFIX% ^
      %SRC_DIR%
if errorlevel 1 exit 1

:: Build.
cmake --build . --config Release
if errorlevel 1 exit 1

:: Test.
ctest -C Release
if errorlevel 1 exit 1

:: Install.
cmake --build . --config Release --target install
if errorlevel 1 exit 1
