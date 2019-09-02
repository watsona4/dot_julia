from __future__ import print_function

from textwrap import dedent

from .convenience import with_message
from .core import get_main


_done = False

def _run_once(ip):
    global _done
    if not _done:
        _done = True
        post_startup_configuration(ip)


def post_startup_configuration(ip):
    from . import ipyext
    ip.run_cell(dedent("""
    %load_ext {ipyext}
    """.format(ipyext=ipyext.__name__)))


def ipython_options(eval_str, api):
    from traitlets.config import Config
    import __main__

    # Use `__main__.__dict__` so that IPython namespace can be
    # retrieved from PyCall using `py"object"`.
    user_ns = __main__.__dict__
    user_ns.update(
        Main=get_main(eval_str=eval_str, api=api),
    )

    c = Config()
    c.TerminalIPythonApp.display_banner = False
    c.TerminalIPythonApp.matplotlib = None  # don't close figures
    c.TerminalInteractiveShell.confirm_exit = False

    # "-i -c <code_to_run>"
    c.InteractiveShellApp.code_to_run = """
    __import__({!r}).{}._run_once(get_ipython())
    """.strip().format(__name__, __name__.split(".", 1)[-1])
    c.InteractiveShellApp.force_interact = True  # "-i"
    #
    # To not override user's `c.InteractiveShellApp.extensions`
    # setting, use `c.InteractiveShellApp.code_to_run` to load our
    # extension.  This is equivalent to passing "-c" option to ipython
    # CLI so it is likely to be not configured in user's IPython
    # profile.  However, `code_to_run` will be invoked every time
    # re-entering to IPython which prints "extension is already
    # loaded" warning.  `_run_once` wrapper is used to avoid that.

    return dict(user_ns=user_ns, config=c)


@with_message
def customized_ipython(eval_str, api):
    import IPython
    print()
    IPython.start_ipython(**ipython_options(eval_str=eval_str, api=api))
