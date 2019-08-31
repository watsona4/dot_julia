pushd build\cmake

:: For dirty builds you may want this (extreme caution, untested and removing files, best to test without | Remove-Item first)
:: powershell.exe "Get-ChildItem -Recurse %CD%| Where-Object { $_.PSIsContainer }| Where-Object {$_.Name -match \".*cmake.*\"}"| Remove-Item
::       --debug-trycompile -Wdev --debug-output --trace  ^


cmake -G"%CMAKE_GENERATOR%"                      ^
      -DCMAKE_INSTALL_PREFIX="%LIBRARY_PREFIX%"  ^
      -DCMAKE_BUILD_TYPE=Release                 ^
      -DCMAKE_C_FLAGS_RELEASE="%CFLAGS%"         ^
      -DCMAKE_CXX_FLAGS_RELEASE="%CXXFLAGS%"     ^
      -DCMAKE_VERBOSE_MAKEFILE=On                ^
      --debug-trycompile -Wdev --debug-output --trace  ^
      .
if %errorlevel% neq 0 exit /b 1

:: Build.
if "%c_compiler%" == "vs2008" goto skip_2015
  cmake --build . --config Release -- -verbosity:detailed
  if %errorlevel% neq 0 exit 1
  cmake --build . --config Release --target install -- -verbosity:detailed
  if %errorlevel% neq 0 exit 1
  goto skip_2008
:skip_2015
  cmake --build . --config Release --target install
  if %errorlevel% neq 0 exit 1
:skip_2008

:: Not working since switching from jom to vc generator.
:: Test.
:: ctest -C Release
::  if not errorlevel 0 exit 1
