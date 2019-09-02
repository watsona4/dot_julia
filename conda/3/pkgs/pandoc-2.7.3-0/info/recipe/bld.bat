msiexec /a pandoc.msi /qb TARGETDIR=%TEMP% || exit 1

if not exist %LIBRARY_BIN% mkdir %LIBRARY_BIN% || exit 1

copy %TEMP%\Pandoc\*.exe %LIBRARY_BIN% || exit 1
