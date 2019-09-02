# HELICS.jl

[![Travis Build Status](https://img.shields.io/travis/com/GMLC-TDC/HELICS.jl/master.svg)](https://travis-ci.com/GMLC-TDC/HELICS.jl) [![Appveyor Build Status](https://img.shields.io/appveyor/ci/kdheepak/helics-jl.svg)](https://ci.appveyor.com/project/kdheepak/helics-jl) [![Docs](https://img.shields.io/badge/docs-latest-blue.svg)](https://gmlc-tdc.github.io/HELICS.jl/latest) [![Codecov](https://img.shields.io/codecov/c/github/gmlc-tdc/HELICS.jl.svg)](https://codecov.io/gh/GMLC-TDC/HELICS.jl) [![Gitter](https://img.shields.io/gitter/room/GMLC-TDC/HELICS-src.svg)](https://gitter.im/GMLC-TDC/HELICS-src) [![Releases](https://img.shields.io/github/tag-date/GMLC-TDC/HELICS.jl.svg)](https://github.com/GMLC-TDC/HELICS.jl/releases)

[HELICS.jl](https://github.com/GMLC-TDC/HELICS.jl) is a cross-platform Julia wrapper around the [HELICS](https://github.com/GMLC-TDC/HELICS-src) library.

**This package is now available for Windows, Mac, and Linux.**

### Documentation

The documentation for the development latest of this package is [here](https://gmlc-tdc.github.io/HELICS.jl/latest/).

### Installation

Use the Julia package manager to install HELICS.jl

```julia
julia> ]
(v1.1)> add HELICS
```

Open the package manager REPL (using `]`)

To install the latest development version, use the following from within Julia:

```julia
(v1.1) pkg> add HELICS#master
```

This package includes HELICS as a library. You do not have to install HELICS
separately.

Note that this should work on 32 and 64-bit Windows systems and 64-bit Linux
and Mac systems.

If you wish to develop `HELICS.jl` you may want to use the following:

```julia
(v1.1) pkg> dev HELICS
```

You can also get a specific version,

```julia
(v1.1) pkg> add HELICS#33c98625
```

or specific branch,


```julia
(v1.1) pkg> add HELICS#kd/some-new-feature
```

if these features haven't been merged to `master` yet.

### Troubleshooting

This package interfaces with HELICS, so a good understanding of HELICS will help troubleshooting.
There are plenty of useful resources located [here](https://gmlc-tdc.github.io/HELICS-src).

If you are having issues using this Julia interface, feel free to open an issue on GitHub [here](https://github.com/GMLC-TDC/HELICS.jl/issues/new).

### Acknowledgements

This work was developed as an extension to work done as part of the Scalable Integrated Infrastructure Planning (SIIP) initiative at the U.S. Department of Energy's National Renewable Energy Laboratory ([NREL](https://www.nrel.gov/)).
