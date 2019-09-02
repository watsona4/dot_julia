import pytest

from ..convenience import print_instruction_on_import_error, package_name, \
    make_instruction, make_dependency_missing_instruction


def raise_ImportError(name):
    try:
        raise ImportError(name=name)
    except TypeError:
        raise ImportError('No module named {}'.format(name))


def test_ipython_not_found(capsys):
    @print_instruction_on_import_error
    def ipython_not_found():
        raise_ImportError('IPython')

    ipython_not_found()

    out, err = capsys.readouterr()
    assert 'Python package "IPython" cannot be imported' in out
    assert 'IPython.install_dependency("ipython")' in out
    assert err == ""


def test_julia_not_found(capsys):
    @print_instruction_on_import_error
    def julia_not_found():
        raise_ImportError('julia')

    julia_not_found()

    out, err = capsys.readouterr()
    assert 'Python package "julia" cannot be imported' in out
    assert 'IPython.install_dependency("julia")' in out
    assert err == ""


def test_unexpected_exception():
    class Unexpected(Exception):
        pass

    @print_instruction_on_import_error
    def exception():
        raise Unexpected()

    with pytest.raises(Unexpected):
        exception()


def test_package_name():
    with pytest.raises(ImportError) as excinfo:
        import __NON_EXISTING_PACKAGE__
        assert __NON_EXISTING_PACKAGE__  # silence pyflakes
    assert package_name(excinfo.value) == '__NON_EXISTING_PACKAGE__'


def test_smoke_make_instruction():
    print(make_instruction('julia'))
    # Print it so that it can be checked by eyes with `pytest -s`.


def test_smoke_make_dependency_missing_instruction():
    import IPython
    print(make_dependency_missing_instruction(IPython, 'traitlets'))
