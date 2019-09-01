# Installation

## Prerequisites
Granular.jl is written as a package for the [Julia programming 
language](https://julialang.org), which is a computationally efficient, yet 
high-level language. Julia also includes a very useful package manager which 
makes it easy to install packages and their requirements, as well as convenient 
updating features.

### Installing Julia
If you do not have Julia installed, download the current release from the 
[official Julia download page](https://julialang.org/downloads), or using your 
system package manager (e.g. `brew cask install julia` on macOS with the 
[Homebrew package manager](https://brew.sh)).  Afterwards, the program `julia` 
can be launched from the terminal.

### Installing Paraview
The core visualization functionality of Granular.jl is based on VTK and 
ParaView.  The most recent stable release can be downloaded from the [ParaView 
downloads page](https://www.paraview.org/download/).  Alternatively, on macOS 
with Homebrew, Paraview can be installed from the terminal with `brew cask 
install paraview`.

## Stable installation (recommended)
The latest stable release of Granular.jl can be installed directly from the 
Julia shell by:

```julia-repl
julia> ]
(v1.0) pkg> add Granular
```

This will install the contents of this repository in the folder 
`~/.julia/packages/Granular` and install its requirements.

## Development installation
If desired, the current developmental version of the [Granular.jl Github 
repository](https://github.com/anders-dc/Granular.jl) can be installed with the 
command:

```julia-repl
julia> ]
(v1.0) pkg> add Granular#master
```

*Please note:* The developmental version is considered unstable and should only 
be used over the stable version if there is a compelling reason to do so.

If you want to modify the code base, install the source code in the 
`~/.julia/dev/` directory with the following command:

```julia-repl
(v1.0) pkg> dev Granular
```

## Package tests
The Granular.jl package contains many tests that verify that the functionality 
works as intended.  The extent of test coverage of the source code is monitored 
and published with [CodeCov](https://codecov.io/gh/anders-dc/Granular.jl).

The package tests are during development continuously run with 
[Travis-CI](https://travis-ci.org/anders-dc/Granular.jl) for Mac (latest stable 
release) and Linux (Ubuntu stable), and 
[AppVeyor](https://ci.appveyor.com/project/anders-dc/seaice-jl) for Windows.

The test scripts are contained in the `test/` directory, can be run locally 
with the following command:

```julia-repl
julia> ]
(v1.0) pkg> test Granular
```

In case any of these tests fail, please open a [Github 
Issue](https://github.com/anders-dc/Granular.jl/issues) describing the problems 
so further investigation and diagnosis can follow.

