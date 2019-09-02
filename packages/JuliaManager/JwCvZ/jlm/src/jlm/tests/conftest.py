import pytest

from .. import cli
from .testing import changingdir


@pytest.fixture
def cleancwd(tmp_path):
    newcwd = tmp_path / "cleancwd"
    with changingdir(newcwd):
        yield newcwd


@pytest.fixture
def initialized(cleancwd):
    cli.run(["--verbose", "init"])
    return cleancwd
