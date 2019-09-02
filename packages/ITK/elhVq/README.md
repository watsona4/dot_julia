# ITK.jl

[![Build Status](https://travis-ci.com/cj-mclaughlin/ITK.jl.svg?branch=master)](https://travis-ci.com/cj-mclaughlin/ITK.jl)
[![Codecov](https://codecov.io/gh/cj-mclaughlin/ITK.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/cj-mclaughlin/ITK.jl)

## Install
```
]add https://github.com/cj-mclaughlin/ITK.jl
using ITK
```

## Current Development Notes
There is currently four parameterized translation registration functions, and two simple test registration functions. Currently working on an option to pass in Julia image arrays, as opposed to only passing in paths to images saved on disk. If there are any specific functions that you would like ported to Julia, feel free to message me directly or write up an issue.

## Docs
Currently unavailable. For now, see comments on source wrappers at src/ITK.jl.

## Build Issues
Currently working on Ubuntu 18.04. Looking to compile backwards and multi-platform in the future.