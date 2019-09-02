# GslibIO.jl

Utilities to read/write *extended* [GSLIB](http://www.gslib.com/gslib_help/format.html) files in Julia.

[![Build Status](https://travis-ci.org/juliohm/GslibIO.jl.svg?branch=master)](https://travis-ci.org/juliohm/GslibIO.jl)
[![Coverage Status](https://codecov.io/gh/juliohm/GslibIO.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/juliohm/GslibIO.jl)

## Introduction

The GSLIB file format was introduced a long time ago for storing regular grids in text files that are easy to read. The format specification is incomplete mainly because:

1. it doesn't contain the size of the grid (i.e. `(nx, ny, nz)`)
2. it doesn't specify the origin and spacing (i.e. `(ox, oy, oz)`, `(sx, sy, sz)`)
3. it doesn't specify the special symbol for inactive cells (e.g. `-999`)

This package introduces an extended GSLIB format that addresses the issues listed above:

```
# optional comment lines at the start of the file
# more comments ...
<nx> <ny> <nz>
<ox> <oy> <oz>
<sx> <sy> <sz>
<property_name1>   <property_name2> ...   <property_nameN>
<property_value11> <property_value12> ... <property_value1N>
<property_value21> <property_value22> ... <property_value2N>
...
<property_value(Nx*Ny*Nz)1> <property_value(Nx*Ny*Nz)2> ... <property_value(Nx*Ny*Nz)N>
```

Inactive cells are marked with the special symbol `NaN`. This means that all properties are saved as floating point numbers regardless of interpretation (categorical or continuous).

## Installation

```julia
Pkg.add("GslibIO")
```

## Usage

This package follows Julia's [FileIO](https://github.com/JuliaIO/FileIO.jl) interface, it provides two functions:

### save

```julia
using FileIO

# save 3D arrays to GSLIB file
save(filename, [array1, array2, ...])
save(filename, array) # version with single array
```
where the following saving options are available:

- `origin` is the origin of the grid (default to `(0.,0.,0.)`)
- `spacing` is the spacing of the grid (default to `(1.,1.,1.)`)
- `header` contains additional comments about the data
- `propnames` is the name of each property being saved (default to `prop1`, `prop2`, ...)

### read

```julia
using FileIO

# read 3D arrays from GSLIB file
grid = load(filename)
```
where

- `filename` **must have** extension `.gslib` or `.sgems`
- `array1`, `array2`, ... are 3D Julia arrays
- `grid` is a `RegularGridData` object

The user can retrieve specific properties of the grid using dictionarly-like syntax
(e.g. `grid[:prop1]`), or retrieve all properties with `values(grid)`. For additional
functionality, please consult the [GeoStats.jl](https://github.com/juliohm/GeoStats.jl)
documentation.
