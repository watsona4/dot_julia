"""
Command line interface to manage Julia's system images.
"""

import argparse
import subprocess
import sys
import textwrap
from pathlib import Path

from .application import Application
from .utils import ApplicationError
from . import __version__

doc_run = """
Run `julia` executable with appropriate system image.

If argument `julia` is not given, the default executable configured by
`jlm init` is used.
"""

doc_init = """
Initialize `jlm`.

`jlm init` does:

* Create a data store (`.jlm` directory).
* Install `JuliaManager.jl` if it is not installed for `<julia>`.
* Compile the "patched" default system image (see note below) for
  `<julia>` if not already found and `--sysimage|-J` is not given.
  This can be done separately by `jlm compile-default-sysimage`.
* Set the system image to be used for `<julia>`.  This can be re-done
  later by `set-sysimage`.

.. NOTE::

   `jlm` compiles the system image with a patch that does `Suggestion:
   Use different precompilation cache path for different system image
   by tkf · Pull Request #29914 · JuliaLang/julia
   <https://github.com/JuliaLang/julia/pull/29914>`_
"""

doc_julia = """
The name of Julia executable on `$PATH` or a path to the Julia
executable.
"""

doc_sysimage = """
The path to system image.
"""


def splitdoc(doc):
    lines = textwrap.dedent((doc or "").lstrip()).splitlines()
    try:
        i = lines.index("")
    except ValueError:
        i = len(lines)
    return "\n".join(lines[:i]), "\n".join(lines[i:])


class FormatterClass(
    argparse.RawDescriptionHelpFormatter, argparse.ArgumentDefaultsHelpFormatter
):
    pass


def make_parser(doc=__doc__):
    parser = argparse.ArgumentParser(formatter_class=FormatterClass, description=doc)

    pyversion = "{0.major}.{0.minor}.{0.micro}".format(sys.version_info)
    parser.add_argument(
        "--version",
        action="version",
        version="%(prog)s {} from {} ({} {})".format(
            __version__, Path(__file__).absolute().parent, sys.executable, pyversion
        ),
    )
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--verbose", "-v", action="store_true")
    parser.add_argument("--pdb", action="store_true")
    parser.add_argument(
        "--jlm-dir",
        metavar="PATH",
        help="""
        Specify the `.jlm` directory which is created by `jlm init`
        and stores information for `jlm`.  By default, `.jlm`
        directory found in the nearest "ancestor" directory is used.
        Run `jlm locate dir` to locate the actual directory that would
        be used.
        """,
    )

    subparsers = parser.add_subparsers()

    def subp(command, func, doc=None):
        title, body = splitdoc(doc or func.__doc__)
        p = subparsers.add_parser(
            command,
            formatter_class=FormatterClass,
            help=title,
            description=title,
            epilog=body,
        )
        p.set_defaults(func=func)
        return p

    p = subp("run", Application.cli_run, doc_run)
    p.add_argument("julia", nargs="?", help=doc_julia)
    p.add_argument(
        "arguments",
        nargs="*",
        help=textwrap.dedent(
            """
            Arguments and options passed to `julia`.  Non-option like
            argument (i.e., the ones *not* starting with `-`)
            following `run` is always interpreted as a Julia
            executable.  To pass a file path to Julia, use `--` as the
            first argument to `run`; i.e.  `jlm ... run --
            PATH/TO/FILE.jl ...`.  If you pass `julia` to `run`, there
            is no need to pass `--` since the argument parsing for
            `jlm` automatically ends at this point.
            """
        ),
    )

    p = subp("init", Application.cli_init, doc_init)
    p.add_argument("julia", nargs="?", help=doc_julia)
    p.add_argument("--sysimage", "-J", help=doc_sysimage)

    p = subp("set-default", Application.cli_set_default)
    p.add_argument("julia", help=doc_julia)

    p = subp("set-sysimage", Application.cli_set_sysimage)
    p.add_argument("julia", nargs="?", help=doc_julia)
    p.add_argument("sysimage", help=doc_sysimage)

    p = subp("unset-sysimage", Application.cli_unset_sysimage)
    p.add_argument("julia", nargs="?", help=doc_julia)

    p = subp("create-default-sysimage", Application.cli_create_default_sysimage)
    p.add_argument("julia", nargs="?", help=doc_julia)
    p.add_argument(
        "--force",
        "-f",
        action="store_true",
        help=textwrap.dedent(
            """
            Re-compile default system image for `julia` even if it
            already exists.
            """
        ),
    )

    p = subp("install-backend", Application.cli_install_backend)
    p.add_argument("julia", nargs="?", help=doc_julia)

    p = subp("update-backend", Application.cli_update_backend)
    p.add_argument("julia", nargs="?", help=doc_julia)

    p = subp("info", Application.cli_info)

    locate_parser = subparsers.add_parser(
        "locate",
        formatter_class=FormatterClass,
        help="Show paths to related files and directories",
    )
    subparsers = locate_parser.add_subparsers()

    p = subp("sysimage", Application.cli_locate_sysimage)
    p.add_argument("julia", nargs="?", help=doc_julia)

    p = subp("base", Application.cli_locate_base)
    p = subp("dir", Application.cli_locate_local_dir)
    p = subp("home-dir", Application.cli_locate_home_dir)

    return parser


def preparse_run(args):
    try:
        stop = args.index("--")
    except ValueError:
        stop = len(args)
    try:
        irun = args.index("run", 0, stop) + 1
    except ValueError:
        return args, None

    # Parse whatever after `run` _unless_ it looks like an option.
    if irun < len(args) and not args[irun].startswith("-"):
        irun += 1
    elif irun < len(args) and args[irun] in ("-h", "--help"):
        irun += 1
    if irun < len(args) and args[irun] == "--":
        irun += 1

    return args[:irun], args[irun:]


def parse_args(args=None):
    if args is None:
        args = sys.argv[1:]
    pre_args, julia_arguments = preparse_run(args)
    parser = make_parser()
    ns = parser.parse_args(pre_args)
    if julia_arguments:
        assert not ns.arguments
        ns.arguments = julia_arguments

    if not hasattr(ns, "func"):
        parser.error("please specify a subcommand or --help")

    if ns.func == Application.cli_init and ns.jlm_dir is not None:
        parser.error("`jlm init` does not support --jlm-dir")

    return ns


def run(args):
    kwargs = vars(parse_args(args))

    enable_pdb = kwargs.pop("pdb")
    if enable_pdb:
        import pdb

    try:
        func = kwargs.pop("func")
        app, kwargs = Application.consume(**kwargs)
        return func(app, **kwargs)
    except Exception:
        if enable_pdb:
            pdb.post_mortem()
        raise


def main(args=None):
    try:
        run(args)
    except (ApplicationError, subprocess.CalledProcessError) as err:
        print(err, file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
