:: SSSE3 is returning errors when compiling with MSVC 9.
if %VS_MAJOR%==9 (
    set SSSE3_FLAG=off
) else (
    set SSSE3_FLAG=on
)

:: MMX is returning errors when linking cairo in 64 bit systems.
if %ARCH%==64 (
    set MMX_FLAG=off
) else (
    set MMX_FLAG=on
)

:: Compiling.
make -f Makefile.win32 SSSE3=%SSSE3_FLAG% MMX=%MMX_FLAG%

:: Installing.
mkdir %LIBRARY_INC%\pixman
move pixman\pixman.h %LIBRARY_INC%\pixman
move pixman\pixman-version.h %LIBRARY_INC%\pixman

move pixman\release\pixman-1.lib %LIBRARY_LIB%
