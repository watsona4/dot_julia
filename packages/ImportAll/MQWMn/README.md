# ImportAll.jl

[![Build Status](https://travis-ci.org/NTimmons/ImportAll.jl.svg?branch=master)](https://travis-ci.org/NTimmons/ImportAll.jl)[![codecov](https://codecov.io/gh/NTimmons/ImportAll.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/NTimmons/ImportAll.jl)

ImportAll.jl is a package which give you the @importall macro to replace the importall command which was depreciated.


### Tutorial
```
using ImportAll
@importall(Base)
```
This will import every function in Base.

This is generally not a good thing to do but is sometimes neccesary.
