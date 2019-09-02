from pathlib import Path

import pytest

from ..datastore import LocalStore
from ..utils import ApplicationError


def test_non_abspath(cleancwd):
    path = cleancwd / "a" / "b" / "c"
    path.mkdir(parents=True)

    store = LocalStore()

    with pytest.raises(ValueError):
        store.path = str(path.relative_to(cleancwd))

    # Should it be an AttributeError?
    with pytest.raises(ApplicationError):
        store.path

    store.path = str(path)
    assert not isinstance(store.path, str)
    assert str(store.path) == str(path)
    if isinstance(str, Path):
        # may not be true in older Python/pytest
        assert store.path == path
