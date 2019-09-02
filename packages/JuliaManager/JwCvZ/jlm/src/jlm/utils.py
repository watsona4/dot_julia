import os
import sys

try:
    Pathish = (str, os.PathLike)
except AttributeError:
    import pathlib

    Pathish = (str, pathlib.PurePath)
    try:
        import pathlib2
    except ImportError:
        pass
    else:
        Pathish += (pathlib2.PurePath,)

iswindows = os.name == "nt"
isapple = sys.platform == "darwin"

# See: Libdl.jl
if isapple:
    dlext = "dylib"
elif iswindows:
    dlext = "dll"
else:
    dlext = "so"


def pathstr(path):
    if not isinstance(path, Pathish):
        raise ValueError("Not a path or a string:\n{!r}".format(path))
    return str(path)


class ApplicationError(RuntimeError):
    pass
