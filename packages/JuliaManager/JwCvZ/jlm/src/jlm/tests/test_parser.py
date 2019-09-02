import pytest

from ..cli import Application, parse_args


def run_args(**kwargs):
    return dict(dict(func=Application.cli_run, julia=None, arguments=[]), **kwargs)


@pytest.mark.parametrize(
    "args, included",
    [
        (["run"], run_args()),
        (["run", "-i"], run_args(arguments=["-i"])),
        (["run", "--", "-i"], run_args(arguments=["-i"])),
        (["run", "-i", "--"], run_args(arguments=["-i", "--"])),
        (["run", "bin/julia"], run_args(julia="bin/julia")),
        (
            ["run", "bin/julia", "--", "-i"],
            run_args(julia="bin/julia", arguments=["-i"]),
        ),
        (
            ["run", "bin/julia", "-i", "--"],
            run_args(julia="bin/julia", arguments=["-i", "--"]),
        ),
    ],
)
def test_parse_args(args, included):
    ns = parse_args(args)
    actual = {k: v for (k, v) in vars(ns).items() if k in included}
    assert actual == included


@pytest.mark.parametrize(
    "args",
    [
        [],
        ["--dry-run"],
        ["--verbose"],
        ["-v"],
        ["--pdb"],
        ["--jlm-dir=path"],
        ["--dry-run", "--verbose", "--pdb", "--jlm-dir=path"],
    ],
)
def test_no_subcommand(capsys, args):
    with pytest.raises(SystemExit):
        parse_args(args)
    captured = capsys.readouterr()
    assert not captured.out
    assert "please specify a subcommand or --help" in captured.err
