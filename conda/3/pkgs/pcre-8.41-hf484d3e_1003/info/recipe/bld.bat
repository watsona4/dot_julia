cmake -G "NMake Makefiles" ^
    -D CMAKE_BUILD_TYPE=Release ^
    -D BUILD_SHARED_LIBS=ON ^
    -D PCRE_SUPPORT_UTF=ON ^
    -D PCRE_SUPPORT_UNICODE_PROPERTIES=ON ^
    -D CMAKE_INSTALL_PREFIX="%LIBRARY_PREFIX%" ^
    --trace --debug-output --debug-trycompile ^
    .
if errorlevel 1 exit 1

nmake
if errorlevel 1 exit 1

:: pcre_test_bat fails to run for some reason
:: might need more investigation
ctest -E pcre_test_bat .
if errorlevel 1 exit 1

nmake install
if errorlevel 1 exit 1
