import os
from contextlib import contextmanager
from pathlib import Path

from ..utils import pathstr


@contextmanager
def changingdir(newcwd):
    oldcwd = Path.cwd()
    newcwd = Path(pathstr(newcwd))
    newcwd.mkdir(parents=True, exist_ok=True)
    os.chdir(pathstr(newcwd))
    try:
        yield newcwd
    finally:
        os.chdir(pathstr(oldcwd))
