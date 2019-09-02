import pytest

from ..ipyext import julia_completer, init_julia_message_on_failure

try:
    from types import SimpleNamespace
except ImportError:
    from argparse import Namespace as SimpleNamespace

try:
    string_types = (unicode, str)
except NameError:
    string_types = (str,)


def make_event(line, text_until_cursor=None, symbol=""):
    if text_until_cursor is None:
        text_until_cursor = line
    return SimpleNamespace(
        line=line,
        text_until_cursor=text_until_cursor,
        symbol=symbol,
    )


completable_events = [
    make_event('Main.eval("'),
    make_event('Main.eval("Base.'),
]

uncompletable_events = [
    make_event(''),
    make_event('Main.eval("', text_until_cursor="Main.e"),
]


def check_version(julia):
    if julia.eval('VERSION < v"0.7-"'):
        raise pytest.skip("Completion not supported in Julia 0.6")


@pytest.mark.parametrize("event", completable_events)
def test_completable_events(julia, event):
    dummy_ipython = None
    completions = julia_completer(julia, dummy_ipython, event)
    assert isinstance(completions, list)
    check_version(julia)
    assert completions
    assert set(map(type, completions)) <= set(string_types)


@pytest.mark.parametrize("event", uncompletable_events)
def test_uncompletable_events(julia, event):
    dummy_ipython = None
    completions = julia_completer(julia, dummy_ipython, event)
    assert isinstance(completions, list)
    check_version(julia)
    assert not completions


def test_inputhook_registration(ipy_with_magic):
    assert ipy_with_magic.active_eventloop == "julia"


def test_init_julia_message_on_failure__with_exception(capsys):
    msg = "exception must be captured"
    with init_julia_message_on_failure():
        raise Exception(msg)
    captured = capsys.readouterr()
    assert not captured.out
    assert msg in captured.err
    assert "It is safe to ignore this exception" in captured.err


def test_init_julia_message_on_failure__no_exception():
    with init_julia_message_on_failure():
        pass
