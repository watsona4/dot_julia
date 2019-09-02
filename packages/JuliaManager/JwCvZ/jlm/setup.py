from setuptools import setup, find_packages

setup(
    name="jlm",
    version="0.1.1",
    packages=find_packages("src"),
    package_dir={"": "src"},
    author="Takafumi Arakaki",
    author_email="aka.tkf@gmail.com",
    url="https://github.com/tkf/JuliaManager.jl",
    license="MIT",  # SPDX short identifier
    # description="jlm - THIS DOES WHAT",
    long_description=open("README.rst").read(),
    # keywords="KEYWORD, KEYWORD, KEYWORD",
    classifiers=[
        "Development Status :: 3 - Alpha",
        "License :: OSI Approved :: MIT License",
        # see: http://pypi.python.org/pypi?%3Aaction=list_classifiers
    ],
    install_requires=[
        # "SOME_PACKAGE",
    ],
    # entry_points={
    #     "console_scripts": ["PROGRAM_NAME = jlm.cli:main"],
    # },
)
