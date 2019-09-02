import os

from distutils.core import setup

if os.environ.get("__JLM_DUMMY_BUILDING__", "no") != "yes":
    raise RuntimeError(
        """
        *** Do not install `jlm` from PyPI ***

        Please read install instruction in
        https://github.com/tkf/JuliaManager.jl
        """
    )

setup(
    name="jlm",
    version="0.0.0",
    author="Takafumi Arakaki",
    author_email="aka.tkf@gmail.com",
    url="https://github.com/tkf/JuliaManager.jl",
    license="MIT",  # SPDX short identifier
    description="*** Do not install `jlm` from PyPI ***",
    long_description="""
    Please read install instruction in
    https://github.com/tkf/JuliaManager.jl
    """,
    # keywords="KEYWORD, KEYWORD, KEYWORD",
    classifiers=[
        "Development Status :: 3 - Alpha",
        # see: http://pypi.python.org/pypi?%3Aaction=list_classifiers
    ],
)
