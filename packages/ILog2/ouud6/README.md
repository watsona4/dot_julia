# ILog2

[![Build Status](https://travis-ci.com/jlapeyre/ILog2.jl.svg?branch=master)](https://travis-ci.com/jlapeyre/ILog2.jl)
[![Build Status](https://ci.appveyor.com/api/projects/status/github/jlapeyre/ILog2.jl?svg=true)](https://ci.appveyor.com/project/jlapeyre/ILog2-jl)
[![Codecov](https://codecov.io/gh/jlapeyre/ILog2.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/jlapeyre/ILog2.jl)
[![Coveralls](https://coveralls.io/repos/github/jlapeyre/ILog2.jl/badge.svg?branch=master)](https://coveralls.io/github/jlapeyre/ILog2.jl?branch=master)

This package provides a fast implementation of `ilog2`.

`ilog2(n::Real)` compute the largest `m` such that `2^m <= n`.
