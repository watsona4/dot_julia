import hashlib
import json
import os
from contextlib import contextmanager
from pathlib import Path
from shutil import which

from . import __version__
from .runtime import JuliaRuntime
from .utils import ApplicationError, Pathish, pathstr


@contextmanager
def atomicopen(path, *args):
    tmppath = Path("{}.{}.tmp".format(path, os.getpid()))
    try:
        with open(pathstr(tmppath), *args) as file:
            yield file
        tmppath.rename(path)
    finally:
        if tmppath.exists():
            os.remove(tmppath)


def locate_localstore(path):
    prev = None
    while path != prev:
        candidate = path / ".jlm"
        if candidate.exists():
            return candidate.resolve()
        prev = path
        path = path.parent
    return None


class BaseStore:
    def execpath(self, julia):
        assert Path(julia).is_absolute()
        m = hashlib.sha1(julia.encode("utf-8"))
        return self.path / "exec" / m.hexdigest()


class HomeStore(BaseStore):

    defaultpath = Path.home() / ".julia" / "jlm"

    def __init__(self, path=defaultpath):
        self.path = Path(path)


class LocalStore(BaseStore):
    @staticmethod
    def is_valid_path(path):
        path = Path(path)
        return (path / "data.json").exists()

    def __init__(self, path=None):
        if path is not None:
            if not isinstance(path, Pathish):
                raise TypeError(
                    (
                        "`path` argument for `LocalStore(path)` must be a"
                        "`str` or `Path`, not {}"
                    ).format(type(path))
                )
            path = Path(path)
            if not self.is_valid_path(path):
                raise ApplicationError(
                    "{} is not a valid `.jlm` directory.".format(path)
                )
            self.path = path

    def locate_path(self):
        try:
            return self._path
        except AttributeError:
            return locate_localstore(Path.cwd())

    def find_path(self):
        path = self.locate_path()
        if path is None:
            raise ApplicationError("Cannot locate `.jlm` local directory")
        return path

    @property
    def path(self):
        try:
            return self._path
        except AttributeError:
            pass

        self.path = self.find_path()
        return self._path

    @path.setter
    def path(self, value):
        path = Path(value)
        if not path.is_absolute():
            raise ValueError("Not an absolute path:\n{}".format(path))
        self._path = path

    def exists(self):
        path = self.locate_path()
        return path is not None and (path / "data.json").exists()

    def loaddata(self):
        if self.exists():
            datapath = self.path / "data.json"
            with open(pathstr(datapath)) as file:
                return json.load(file)
        return {
            "name": "jlm.LocalStore",
            "jlm_version": __version__,
            "config": {"runtime": {}},
        }

    def storedata(self, data):
        with atomicopen(self.path / "data.json", "w") as file:
            json.dump(data, file)

    def set(self, config):
        data = self.loaddata()

        if "default" in config:
            assert isinstance(config["default"], str)
            data["config"]["default"] = config["default"]
        if "runtime" in config:
            data["config"]["runtime"].update(config["runtime"])

        self.storedata(data)

    def has_default_julia(self):
        return "default" in self.loaddata()["config"]

    @property
    def default_julia(self):
        config = self.loaddata()["config"]
        try:
            return config["default"]
        except KeyError:
            raise AttributeError

    def sysimage(self, julia):
        runtime = self.loaddata()["config"]["runtime"]
        try:
            return runtime[julia]["sysimage"]
        except KeyError:
            return None

    def set_sysimage(self, julia, sysimage):
        assert isinstance(julia, str)
        config = self.loaddata()["config"]
        config["runtime"][julia] = {"sysimage": pathstr(sysimage)}
        self.set(config)

    def unset_sysimage(self, julia):
        if not isinstance(julia, str):
            raise TypeError("`julia` must be a `str`, got: {!r}".format(julia))
        data = self.loaddata()
        data["config"]["runtime"].pop(julia, None)
        self.storedata(data)

    def available_runtimes(self):
        config = self.loaddata()["config"]
        try:
            julia = config["default"]
        except KeyError:
            julia = which("julia")
        default = JuliaRuntime(julia, self.sysimage(julia))

        others = []
        for (julia, runtime) in config["runtime"].items():
            if julia != default.executable:
                others.append(JuliaRuntime(julia, runtime["sysimage"]))

        return default, others
