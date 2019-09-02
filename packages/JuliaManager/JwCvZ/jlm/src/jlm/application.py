import os
import shlex
import subprocess
import sys
import textwrap
from pathlib import Path
from shutil import which

from .datastore import HomeStore, LocalStore
from .utils import ApplicationError, dlext, pathstr


class SideEffect:
    @classmethod
    def consume(cls, dry_run, verbose, **kwargs):
        return cls(dry_run, verbose), kwargs

    def __init__(self, dry_run, verbose):
        self.dry_run = dry_run
        self.verbose = verbose
        self._verbose = dry_run or verbose

    def print(self, message=""):
        print(message)
        # TODO: hide when "quiet"

    def info(self, message):
        if self._verbose:
            print(message)

    def warn(self, message):
        print(message, file=sys.stderr)

    def info_run(self, cmd):
        self.info("Run: " + " ".join(map(shlex.quote, cmd)))

    def check_call(self, cmd, **kwargs):
        self.info_run(cmd)
        if self.dry_run:
            return
        subprocess.check_call(cmd, *kwargs)

    def ensuredir(self, path):
        path = Path(path)
        if path.is_dir():
            return
        self.info("Directory {} does not exist. Creating...".format(path))
        if not self.dry_run:
            path.mkdir(parents=True)


class Application:
    @classmethod
    def consume(cls, dry_run, verbose, julia=None, jlm_dir=None, **kwargs):
        return cls(dry_run, verbose, julia, jlm_dir), kwargs

    def __init__(self, dry_run, verbose, julia, jlm_dir=None):
        # TODO: do not put `julia` in `self.juila`
        _julia = julia
        if julia is not None:
            _julia = which(julia)
            if _julia is None:
                raise ApplicationError("Julia executable {} is not found".format(julia))

        self.dry_run = dry_run
        self.verbose = verbose
        self.julia = _julia
        self.eff = SideEffect(dry_run, verbose)

        if jlm_dir is not None:
            jlm_dir = Path(jlm_dir)
            if LocalStore.is_valid_path(jlm_dir):
                jlm_dir = jlm_dir.resolve()
            else:
                possible = jlm_dir / ".jlm"
                if possible.exists():
                    self.eff.warn(
                        (
                            "{jlm_dir} is not a valid path for --jlm-dir.  "
                            "Do you forget to append `.jlm`?  Possible fix:\n"
                            "    --jlm-dir {possible}"
                        ).format(jlm_dir=jlm_dir, possible=possible)
                    )

        self.homestore = HomeStore()
        self.localstore = LocalStore(jlm_dir)

    sysimage_name = "sys." + dlext

    def default_sysimage(self, julia):
        return self.homestore.execpath(julia) / self.sysimage_name

    def sysimage_for(self, julia):
        return self.localstore.sysimage(julia) or self.default_sysimage(julia)

    @property
    def effective_sysimage(self):
        return self.sysimage_for(self.effective_julia)

    @property
    def effective_julia(self):
        if self.julia is not None:
            return self.julia
        try:
            return self.localstore.default_julia
        except AttributeError:
            pass
        julia = which("julia")
        if julia is None:
            raise ApplicationError("Julia executable `julia` is not found.")
        return julia

    def julia_cmd(self):
        cmd = [pathstr(self.effective_julia)]
        cmd.extend(["--sysimage", pathstr(self.effective_sysimage)])
        return cmd

    @property
    def precompile_key(self):
        """
        Bytes ("salt") to be included for computing precompilation paths' slug.

        See ``$JLM_PRECOMPILE_KEY`` in
        ``../../../src/SysImageHack/scripts/patch.jl``.
        """
        return pathstr(self.localstore.path)

    def update_backend(self, julia):
        code = """
        using Pkg
        Pkg.add("JuliaManager")
        """
        try:
            self.eff.check_call([julia, "--startup-file=no", "--color=yes", "-e", code])
        except subprocess.CalledProcessError:
            raise ApplicationError("Failed to update JuliaManager.jl")

    def install_backend(self, julia):
        code = """
        pkg = Base.PkgId(
            Base.UUID("0cdbb3b1-e653-5045-b8d5-b31a04c2a6c9"),
            "JuliaManager",
        )
        if Base.locate_package(pkg) === nothing
            @info "JuliaManager.jl is not found. Installing..."
            using Pkg
            Pkg.add("JuliaManager")
        else
            @info "JuliaManager.jl is already installed"
        end
        """
        try:
            self.eff.check_call([julia, "--startup-file=no", "--color=yes", "-e", code])
        except subprocess.CalledProcessError:
            raise ApplicationError("Failed to install JuliaManager.jl")

    def compile_patched_sysimage(self, julia, sysimage):
        code = """
        using JuliaManager: compile_patched_sysimage
        compile_patched_sysimage(ARGS[1])
        """
        self.eff.check_call([julia, "--startup-file=no", "-e", code, pathstr(sysimage)])

    def create_default_sysimage(self, julia):
        sysimage = self.default_sysimage(julia)
        self.eff.ensuredir(sysimage.parent)
        self.compile_patched_sysimage(julia, sysimage)

    def ensure_default_sysimage(self, julia):
        self.install_backend(julia)
        sysimage = self.default_sysimage(julia)
        if sysimage.exists():
            self.eff.print("Default system image {} already exists.".format(sysimage))
            return
        self.create_default_sysimage(julia)

    def normalize_sysimage(self, sysimage):
        sysimage = Path(sysimage)
        if not sysimage.is_absolute():
            sysimage = Path.cwd() / sysimage
            # Don't `.resolve()` here to avoid resolving symlinks.
            # User may re-link sysimage and `jlm run` to use the new
            # target.  It would be useful, e.g., when sysimage is
            # stored in git-annex.
        return pathstr(sysimage)

    def initialize_localstore(self):
        self.localstore.path = Path.cwd() / ".jlm"
        self.eff.ensuredir(self.localstore.path)

    def available_runtimes(self):
        default, others = self.localstore.available_runtimes()
        return default.resolve(self), [runtime.resolve(self) for runtime in others]

    def cli_run(self, arguments):
        assert all(isinstance(a, str) for a in arguments)
        env = os.environ.copy()
        env["JLM_PRECOMPILE_KEY"] = self.precompile_key
        cmd = self.julia_cmd()
        cmd.extend(arguments)
        self.eff.info_run(cmd)
        if self.dry_run:
            return
        os.execvpe(cmd[0], cmd, env)

    def cli_init(self, sysimage):
        self.initialize_localstore()
        julia = self.julia
        effective_julia = self.effective_julia  # `julia` or which("julia")
        config = {}
        if julia:
            config["default"] = julia
        if sysimage:
            sysimage = self.normalize_sysimage(sysimage)
            config.update({"runtime": {effective_julia: {"sysimage": sysimage}}})
        else:
            self.ensure_default_sysimage(effective_julia)
        if not self.dry_run:
            self.localstore.set(config)

    def cli_set_default(self):
        """ Set default Julia executable to be used. """
        self.localstore.set({"default": self.julia})

    def cli_set_sysimage(self, sysimage):
        """ Set system image for `juila`. """

        sysimage = self.normalize_sysimage(sysimage)

        # In case --julia is not specified, it is probably better to
        # resolve Julia executable at this point rather than to use
        # whatever `julia` on the `$PATH` sometime later at run-time.
        julia = self.effective_julia

        self.localstore.set_sysimage(julia, sysimage)

        self.eff.print(
            textwrap.dedent(
                """
                System image is set to:
                    {}
                for Julia executable:
                    {}
                """.format(
                    sysimage, julia
                )
            )
        )

    def cli_unset_sysimage(self):
        """ Unset system image for `juila`. """
        julia = self.effective_julia
        self.localstore.unset_sysimage(julia)

    def cli_create_default_sysimage(self, force):
        """ Compile default system image for `julia`. """
        julia = self.effective_julia
        if force:
            self.create_default_sysimage(julia)
        else:
            self.ensure_default_sysimage(julia)

    def cli_install_backend(self):
        """ Install JuliaManager.jl for this `julia`. """
        self.install_backend(self.effective_julia)

    def cli_update_backend(self):
        """ Update JuliaManager.jl for this `julia`. """
        self.update_backend(self.effective_julia)

    def cli_info(self):
        """ Print information about jlm setup. """
        path = self.localstore.path
        default, others = self.available_runtimes()

        print = self.eff.print
        print()
        print("`.jlm` directory:")
        print(path)
        print()
        print("Default Julia runtime:")
        print(default.summary())
        if others:
            print()
            print("Other runtime(s):")
            for runtime in others:
                print(runtime.summary())

    def cli_locate_sysimage(self):
        """ Print system image that would be used for `julia`. """
        print(self.effective_sysimage, end="")

    def cli_locate_base(self):
        """ Print directory for which `jlm init` was executed. """
        print(self.localstore.path.parent, end="")

    def cli_locate_local_dir(self):
        """ Print directory in which `jlm` information is stored. """
        print(self.localstore.path, end="")

    def cli_locate_home_dir(self):
        """ Print directory in which `jlm` global information is stored. """
        print(self.homestore.path, end="")
