# PCRE2

| **Info** | **Windows** | **Linux & MacOS** | **Package Evaluator** | **CodeCov** | **Coveralls** |
|:------------------:|:------------------:|:---------------------:|:-----------------:|:---------------------:|:-----------------:|
| [![][license-img]][license-url] | [![][app-s-img]][app-s-url] | [![][travis-s-img]][travis-url] | [![][pkg-s-img]][pkg-s-url] | [![][codecov-img]][codecov-url] | [![][coverall-s-img]][coverall-s-url]
| [![][gitter-img]][gitter-url] | [![][app-m-img]][app-m-url] | [![][travis-m-img]][travis-url] | [![][pkg-m-img]][pkg-m-url] | [![][codecov-img]][codecov-url] | [![][coverall-m-img]][coverall-m-url]

[license-img]:  http://img.shields.io/badge/license-MIT-brightgreen.svg?style=flat
[license-url]:  LICENSE.md

[gitter-img]:   https://badges.gitter.im/Join%20Chat.svg
[gitter-url]:   https://gitter.im/JuliaString/Lobby?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge

[travis-url]:   https://travis-ci.org/JuliaString/PCRE2.jl
[travis-s-img]: https://travis-ci.org/JuliaString/PCRE2.jl.svg
[travis-m-img]: https://travis-ci.org/JuliaString/PCRE2.jl.svg?branch=master

[app-s-url]:    https://ci.appveyor.com/project/ScottPJones/pcre2-jl
[app-m-url]:    https://ci.appveyor.com/project/ScottPJones/pcre2-jl/branch/master
[app-s-img]:    https://ci.appveyor.com/api/projects/status/d62uhoik906m7n8r?svg=true
[app-m-img]:    https://ci.appveyor.com/api/projects/status/d62uhoik906m7n8r/branch/master?svg=true

[pkg-s-url]:    http://pkg.julialang.org/detail/PCRE2
[pkg-m-url]:    http://pkg.julialang.org/detail/PCRE2
[pkg-s-img]:    http://pkg.julialang.org/badges/PCRE2_0.6.svg
[pkg-m-img]:    http://pkg.julialang.org/badges/PCRE2_0.7.svg

[codecov-url]:  https://codecov.io/gh/JuliaString/PCRE2.jl
[codecov-img]:  https://codecov.io/gh/JuliaString/PCRE2.jl/branch/master/graph/badge.svg

[coverall-s-url]: https://coveralls.io/github/JuliaString/PCRE2.jl
[coverall-m-url]: https://coveralls.io/github/JuliaString/PCRE2.jl?branch=master
[coverall-s-img]: https://coveralls.io/repos/github/JuliaString/PCRE2.jl/badge.svg
[coverall-m-img]: https://coveralls.io/repos/github/JuliaString/PCRE2.jl/badge.svg?branch=master

The `PCRE2` package implements a low-level API for accessing the PCRE libraries (8, 16, and 32-bit)
It is intended to replace `Base.PCRE`, which is not threadsafe, only supports UTF-8, and is using an old version of the PCRE library (10.30, current version is 10.31)
