# StressTest.jl

A collection of convenience functions for stress testing purposes.

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://ianshmean.github.io/StressTest.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://ianshmean.github.io/StressTest.jl/dev)
[![Build Status](https://travis-ci.com/ianshmean/StressTest.jl.svg?branch=master)](https://travis-ci.com/ianshmean/StressTest.jl)
[![Build Status](https://ci.appveyor.com/api/projects/status/github/ianshmean/StressTest.jl?svg=true)](https://ci.appveyor.com/project/ianshmean/StressTest-jl)
[![Codecov](https://codecov.io/gh/ianshmean/StressTest.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/ianshmean/StressTest.jl)
[![Coveralls](https://coveralls.io/repos/github/ianshmean/StressTest.jl/badge.svg?branch=master)](https://coveralls.io/github/ianshmean/StressTest.jl?branch=master)
[![Build Status](https://api.cirrus-ci.com/github/ianshmean/StressTest.jl.svg)](https://cirrus-ci.com/github/ianshmean/StressTest.jl)

## CPU loading
- `dream(seconds)` - Like `Base.sleep(seconds)` except it maxes out the thread

For instance, for testing multithreaded CPU loading in Julia 1.3-alpha
```julia
using StressTest
Threads.@spawn dream(10)
Threads.@spawn dream(10)
Threads.@spawn dream(10)
Threads.@spawn dream(10)
(System monitor then shows julia ramping up to ~400% for 10 seconds)
```


PR's welcome!
