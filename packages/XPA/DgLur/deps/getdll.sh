#! /bin/sh
#
# Simple script to figure out the path of a dynamic library given an executable
# that has been linked against that library.

if test $# -ne 2; then
    echo >&2 "usage: $0 LIB EXE"
    exit 1
fi
LIB=$1
EXE=$2

case `uname` in
    Linux)
        script='/^[ \t]*lib'$LIB'\.so.*=>/{s/^.*=>[ \t]*//;s/[ \t]*(0x[0-9A-Fa-f]*)[ \t]*$//;p}'
        dll=$(ldd "$EXE" | sed -n "$script")
        ;;
    Darwin)
        script='/lib'$LIB'\.dylib/{s/^[ \t]*//;s/[ \t]*([^)]*)[ \t]*$//;p}'
        dll=$(otool -L "$EXE" | sed -n "$script")
        ;;
    *)
    echo >&2 "$0: unknown system"
    exit 1
esac

if test "$dll" = "";  then
    echo >&2 "$0: dynamic library '$LIB' not found in executable '$EXE'"
    exit 1
fi
echo "$dll"
