# StataDTAFiles

![Lifecycle](https://img.shields.io/badge/lifecycle-experimental-orange.svg)
[![Build Status](https://travis-ci.org/tpapp/StataDTAFiles.jl.svg?branch=master)](https://travis-ci.org/tpapp/StataDTAFiles.jl)
[![Coverage Status](https://coveralls.io/repos/tpapp/StataDTAFiles.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/tpapp/StataDTAFiles.jl?branch=master)
[![codecov.io](http://codecov.io/github/tpapp/StataDTAFiles.jl/coverage.svg?branch=master)](http://codecov.io/github/tpapp/StataDTAFiles.jl?branch=master)

Read DTA files from Stata.

This package provides low-level functions for reading (and in the future, writing) the DTA format that Stata uses for data files, written in native Julia, with no external dependencies.

You can use this package directly, or as a *basis for implementing high-level routines* that read to `DataFrame`s, etc.

## Usage

The primary entry point/recommended usage is is

```julia
open(DTAFile, ...) do dta
    ...
end
```
where the method for `open` would open the DTA file, read some metadata (byte order, layout, etc), and provide an iterator for the rows.

Date conversion is provided by `elapsed_days`.

See the unit tests for examples.

## Caveats

- work in progress, API is subject to change,
- variable-length strings (`StrL`) not yet supported,
- currently format 118 is supported, 119 is planned,
- test coverage is incomplete,
- some metadata reading is WIP.

## Documentation of Stata DTA format

- [Stata 15 help](https://www.stata.com/help.cgi?dta)
- [Library of Congress on *Stata Data Format (`.dta`), Version 118*](https://www.loc.gov/preservation/digital/formats/fdd/fdd000471.shtml)
