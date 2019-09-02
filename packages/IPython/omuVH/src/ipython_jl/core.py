# TODO: replace object.__XXX__(self, ...) with super().__XXX__(...)
# once Python 2 support is removed.

from __future__ import print_function

import sys
import types

try:
    from importlib import reload
except ImportError:
    try:
        from imp import reload
    except ImportError:
        pass  # Python 2?

_Main = None


def jl_name(name):
    if name.endswith('_b'):
        return name[:-2] + '!'
    return name


def py_name(name):
    if name.endswith('!'):
        return name[:-1] + '_b'
    return name


class JuliaAPI(object):

    def __init__(self, eval_str, api):
        self.eval = eval_str
        self.api = api

    def __getattr__(self, name):
        return self.eval(name, scope=self.api)


class JuliaNameSpace(object):

    def __init__(self, julia):
        self.__julia = julia
        self.__scope = julia.eval("Main")

    eval = property(lambda self: self.__julia.eval)

    def __setattr__(self, name, value):
        if name.startswith('_'):
            object.__setattr__(self, name, value)
            # super().__setattr__(name, value)
        else:
            self.__julia.setattr(self.__scope, name, value)

    def __getattr__(self, name):
        if name.startswith('_'):
            return object.__getattr__(self, name)
            # return super().__getattr__(name)
        else:
            return self.__julia.eval(jl_name(name))

    @property
    def __all__(self):
        names = self.__julia.eval("names(Main)")
        return list(map(py_name, names))

    def __dir__(self):
        if sys.version_info.major == 2:
            names = set()
        else:
            names = set(super().__dir__())
        names.update(self.__all__)
        return list(names)
    # Override __dir__ method so that completing member names work
    # well in Python REPLs like IPython.


def get_api(main):
    if main is None:
        return None
    return main._JuliaNameSpace__julia


def get_cached_api():
    return get_api(_Main)


def get_main(**kwargs):
    """
    Create or get cached `Main`.

    Caching is required to avoid re-writing to `_Main` when re-entering
    to IPython session (where `user_ns` would be ignored).
    """
    global _Main
    if _Main is None:
        _Main = JuliaNameSpace(JuliaAPI(**kwargs))
    return _Main


def revise():
    """Ad-hoc hot reload."""

    Main = _Main

    import ipython_jl
    reload(ipython_jl.core)

    if Main is not None:
        Main.__class__ = ipython_jl.core.JuliaNameSpace
        Main._JuliaNameSpace__julia.__class__ = ipython_jl.core.JuliaAPI
        ipython_jl.core._Main = Main

    try:
        ipython_jl.ipyext
    except AttributeError:
        pass
    else:
        reload(ipython_jl.ipyext)

    try:
        ipython_jl.tests
    except AttributeError:
        return

    # *Try* reloading modules `ipython_jl.tests.*`.  If there are
    # dependencies between those modules, it's not going to work.
    for (name, module) in sorted(vars(ipython_jl.tests).items(),
                                 key=lambda pair: pair[0]):
        if isinstance(module, types.ModuleType):
            reload(module)

    reload(ipython_jl)
