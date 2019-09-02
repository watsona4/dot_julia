from __future__ import print_function

from contextlib import contextmanager
import os
import sys
import traceback

from .core import get_cached_api

try:
    from .key_bindings import register_key_bindings
except ImportError:
    def register_key_bindings(_):
        return lambda: None


def _unregister_key_bindings():
    """ No-op placeholder function to be replaced. """


def julia_completer(julia, self, event):
    pos = event.text_until_cursor.find("Main.eval")
    if pos < 0:
        return []
    pos += len("Main.eval('")  # pos: beginning of Julia code
    julia_code = event.line[pos:]
    julia_pos = len(event.text_until_cursor) - pos
    completions = julia.completions(julia_code, julia_pos)
    if "." in event.symbol:
        # When completing "Base.Enums.s" we need to add prefix "Base.Enums"
        prefix = event.symbol.rsplit(".", 1)[0]
        completions = [".".join((prefix, c)) for c in completions]
    global last_completions, last_event
    last_completions = completions
    last_event = event
    return completions
# See:
# IPython.core.completer.dispatch_custom_completer


def _julia_completer(self, event):
    return julia_completer(get_cached_api(), self, event)


def julia_inputhook(context):
    """
    Hook to be run when IPython is idle.

    This is passed to `prompt_toolkit.PromptSession` as `inputhook` argument
    via `IPython`.

    Parameters
    ----------
    context : InputHookContext
        See: https://github.com/jonathanslenders/python-prompt-toolkit/blob/master/prompt_toolkit/eventloop/inputhook.py
    """
    julia = get_cached_api()
    jl_sleep = julia.sleep
    while not context.input_is_ready():
        jl_sleep(0.05)


@contextmanager
def init_julia_message_on_failure():
    try:
        yield
    except Exception:
        traceback.print_exc()
        print(file=sys.stderr)
        print("Executing `julia.Julia(init_julia=False)` failed.",
              "It is safe to ignore this exception unless you are",
              "going to use PyJulia.",
              file=sys.stderr)
        print("To suppress automatic PyJulia initialization,",
              "set environment variable `IPYTHON_JL_SETUP_PYJULIA`",
              'to "no".',
              file=sys.stderr)


def maybe_load_pyjulia():
    """
    Execute ``julia.Julia(init_julia=False)`` if appropriate.

    It is useful since it skips initialization when creating the
    global "cached" API.  This makes PyJuli initialization slightly
    faster and also makes sure to not load incompatible `libjulia`
    when the name of the julia command of this process is not `julia`.
    """
    if (os.environ.get("IPYTHON_JL_SETUP_PYJULIA", "yes").lower()
            in ("yes", "t", "true")):
        try:
            from julia import Julia
        except ImportError:
            pass
        else:
            with init_julia_message_on_failure():
                Julia(init_julia=False)


def load_ipython_extension(ip):
    global _unregister_key_bindings
    _unregister_key_bindings = register_key_bindings(ip)

    from IPython.terminal.pt_inputhooks import register
    register("julia", julia_inputhook)
    if not ip.active_eventloop:
        ip.enable_gui("julia")

    maybe_load_pyjulia()

    ip.set_hook("complete_command", _julia_completer,
                re_key=r""".*\bMain\.eval\(["']""")
# See:
# https://ipython.readthedocs.io/en/stable/api/generated/IPython.core.hooks.html
# IPython.core.interactiveshell.init_completer
# IPython.core.completerlib (quick_completer etc.)


def unload_ipython_extension(ip):
    _unregister_key_bindings()
