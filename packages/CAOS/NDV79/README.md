# CAOS

#### Characteristic Attribute Organization System (CAOS) implementation in Julia.


| MacOS / Linux | Windows | Test Coverage | Documentation | Lifecycle |
| --- | ---- | ------ | ------ | ---- |
|[![Travis](https://img.shields.io/travis/bcbi/CAOS.jl/master.svg?style=flat-square)](https://travis-ci.org/bcbi/CAOS.jl)| [![AppVeyor](https://img.shields.io/appveyor/ci/fernandogelin/CAOS-jl/master.svg?style=flat-square)](https://ci.appveyor.com/project/fernandogelin/caos-jl) | [![Codecov](https://img.shields.io/codecov/c/github/bcbi/CAOS.jl.svg?style=flat-square)](https://codecov.io/gh/bcbi/CAOS.jl/branch/master) | [![Docs](https://img.shields.io/badge/docs-stable-blue.svg?style=flat-square)](https://bcbi.github.io/CAOS.jl/stable) [![Docs](https://img.shields.io/badge/docs-latest-blue.svg?style=flat-square)](https://bcbi.github.io/CAOS.jl/latest) | ![Lifecycle](https://img.shields.io/badge/lifecycle-maturing-blue.svg?style=flat-square) |

## Installation


### Requirements
- [BLAST][blast-url] 2.7.1+ installed and accessible in your PATH (eg. you should be able to execute `$ blastn -h` from the command line).

Install BLAST with Anaconda:

```bash
conda install blast -c bioconda
```

[blast-url]: https://blast.ncbi.nlm.nih.gov/Blast.cgi?CMD=Web&PAGE_TYPE=BlastDocs&DOC_TYPE=Download

Instal CAOS.jl

```julia
using Pkg
Pkg.clone("https://github.com/bcbi/CAOS.jl")
```

## Contributing

Contributions consistent with the style and quality of existing code are
welcome. Be sure to follow the guidelines below.

Check the issues page of this repository for available work.

### Committing


This project uses [commitizen](https://pypi.org/project/commitizen/)
to ensure that commit messages remain well-formatted and consistent
across different contributors.

Before committing for the first time, install commitizen and read
[Conventional
Commits](https://www.conventionalcommits.org/en/v1.0.0-beta.2/).

```bash
pip install commitizen
```

To start work on a new change, pull the latest `develop` and create a
new *topic branch* (e.g. feature-resume-model`,
`chore-test-update`, `bugfix-bad-bug`).

```bash
git add .
```

To commit, run the following command (instead of ``git commit``) and
follow the directions:


```bash
cz commit
```


## Project Status

The package is tested against the current Julia `1.0` and Julia `1.1` release on OS X and Linux.

## Contributing and Questions

Contributions are very welcome, as are feature requests and suggestions. Please open an
[issue][issues-url] if you encounter any problems or would just like to ask a question.

[issues-url]: https://github.com/bcbi/CAOS/issues
