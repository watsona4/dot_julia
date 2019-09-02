import os
import subprocess
import sys

import pytest

from .. import cli
from ..utils import ApplicationError, dlext, pathstr
from .testing import changingdir


def test_init(initialized):
    assert (initialized / ".jlm").is_dir()


@pytest.mark.parametrize(
    "args",
    [
        ["install-backend"],
        ["create-default-sysimage"],
        ["--dry-run", "create-default-sysimage", "--force"],
        ["set-default", "julia"],
        ["set-sysimage", "/dev/null"],
        ["unset-sysimage"],
        ["info"],
        ["locate", "sysimage"],
        ["locate", "sysimage", "julia"],
        ["locate", "base"],
        ["locate", "dir"],
        ["locate", "home-dir"],
    ],
)
def test_smoke(initialized, args):
    cli.run(args)


@pytest.mark.parametrize(
    "args",
    [
        ["--dry-run", "create-default-sysimage"],
        ["--dry-run", "create-default-sysimage", "--force"],
        ["locate", "home-dir"],
    ],
)
def test_smome_non_initialized(args):
    cli.run(args)


def test_locate_fail_outside(initialized, tmp_path):
    with changingdir(tmp_path / "different_dir"):
        with pytest.raises(ApplicationError):
            cli.run(["locate", "dir"])


def test_locate_jlm_dir(initialized, tmp_path, capsys):
    jlm_dir = str(initialized / ".jlm")
    with changingdir(tmp_path / "different_dir"):
        cli.run(["--jlm-dir", jlm_dir, "locate", "dir"])
    captured = capsys.readouterr()
    assert captured.out == jlm_dir


@pytest.mark.parametrize("is_base", [False, True])
def test_locate_fail_non_jlm_dir(initialized, tmp_path, capsys, is_base):
    jlm_dir = str(initialized if is_base else tmp_path / "another")
    with changingdir(tmp_path / "different_dir"):
        with pytest.raises(ApplicationError) as exc_info:
            cli.run(["--jlm-dir", jlm_dir, "locate", "dir"])
    captured = capsys.readouterr()
    assert not captured.out
    if is_base:
        assert "Possible fix:" in captured.err
    assert "is not a valid `.jlm` directory" in str(exc_info.value)


def test_jlm_dir_locate_sysimage(initialized, tmp_path, capsys):
    sysimage = str(tmp_path / "dummy-sys.so")
    cli.run(["set-sysimage", sysimage])
    capsys.readouterr()

    jlm_dir = str(initialized / ".jlm")
    with changingdir(tmp_path / "different_dir"):
        cli.run(["--jlm-dir", jlm_dir, "locate", "sysimage"])

    captured = capsys.readouterr()
    assert captured.out == sysimage


def test_jlm_dir_dry_run(initialized, tmp_path, capsys):
    sysimage = str(tmp_path / "dummy-sys.so")
    cli.run(["set-sysimage", sysimage])
    capsys.readouterr()

    jlm_dir = str(initialized / ".jlm")
    with changingdir(tmp_path / "different_dir"):
        cli.run(["--jlm-dir", jlm_dir, "--dry-run", "run"])

    captured = capsys.readouterr()
    assert sysimage in captured.out


def test_run(initialized):
    subprocess.check_call(
        [
            sys.executable,
            "-m",
            cli.__name__,
            "--verbose",
            "run",
            "--startup-file=no",
            "-e",
            "Base.banner()",
        ]
    )


def test_relative_sysimage(initialized):
    app = cli.Application(dry_run=False, verbose=True, julia="julia")

    sysimage = initialized / "some" / "dir" / ("sys." + dlext)
    sysimage.parent.mkdir(parents=True)
    sysimage.symlink_to(app.default_sysimage(app.julia))

    cli.run(["--verbose", "set-sysimage", pathstr(sysimage.relative_to(initialized))])
    test_run(initialized)
    cli.run(["locate", "sysimage"])
    print()

    otherdir = initialized / "some" / "other" / "dir"
    otherdir.mkdir(parents=True)
    os.chdir(pathstr(otherdir))

    test_run(initialized)
    cli.run(["locate", "sysimage"])
    print()
