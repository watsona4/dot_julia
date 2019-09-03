# StrRegex

| **Info** | **Windows** | **Linux & MacOS** | **Package Evaluator** | **CodeCov** | **Coveralls** |
|:------------------:|:------------------:|:---------------------:|:-----------------:|:---------------------:|:-----------------:|
| [![][license-img]][license-url] | [![][app-s-img]][app-s-url] | [![][travis-s-img]][travis-url] | [![][pkg-s-img]][pkg-s-url] | [![][codecov-img]][codecov-url] | [![][coverall-s-img]][coverall-s-url]
| [![][gitter-img]][gitter-url] | [![][app-m-img]][app-m-url] | [![][travis-m-img]][travis-url] | [![][pkg-m-img]][pkg-m-url] | [![][codecov-img]][codecov-url] | [![][coverall-m-img]][coverall-m-url]

[license-img]:  http://img.shields.io/badge/license-MIT-brightgreen.svg?style=flat
[license-url]:  LICENSE.md

[gitter-img]:   https://badges.gitter.im/Join%20Chat.svg
[gitter-url]:   https://gitter.im/JuliaString/Lobby?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge

[travis-url]:   https://travis-ci.org/JuliaString/StrRegex.jl
[travis-s-img]: https://travis-ci.org/JuliaString/StrRegex.jl.svg
[travis-m-img]: https://travis-ci.org/JuliaString/StrRegex.jl.svg?branch=master

[app-s-url]:    https://ci.appveyor.com/project/ScottPJones/strregex-jl
[app-m-url]:    https://ci.appveyor.com/project/ScottPJones/strregex-jl/branch/master
[app-s-img]:    https://ci.appveyor.com/api/projects/status/iyhlb4unq5ml4g0w?svg=true
[app-m-img]:    https://ci.appveyor.com/api/projects/status/iyhlb4unq5ml4g0w/branch/master?svg=true

[pkg-s-url]:    http://pkg.julialang.org/detail/StrRegex
[pkg-m-url]:    http://pkg.julialang.org/detail/StrRegex
[pkg-s-img]:    http://pkg.julialang.org/badges/StrRegex_0.6.svg
[pkg-m-img]:    http://pkg.julialang.org/badges/StrRegex_0.7.svg

[codecov-url]:  https://codecov.io/gh/JuliaString/StrRegex.jl
[codecov-img]:  https://codecov.io/gh/JuliaString/StrRegex.jl/branch/master/graph/badge.svg

[coverall-s-url]: https://coveralls.io/github/JuliaString/StrRegex.jl
[coverall-m-url]: https://coveralls.io/github/JuliaString/StrRegex.jl?branch=master
[coverall-s-img]: https://coveralls.io/repos/github/JuliaString/StrRegex.jl/badge.svg
[coverall-m-img]: https://coveralls.io/repos/github/JuliaString/StrRegex.jl/badge.svg?branch=master

The `StrRegex` package adds Regex support to the `Strs` package, as well as fix some issues present in the base Regex support.

* Thread-safe support
* Allows the whole range of compile and match options
* Supports both UTF and non-UTF strings
* Supports strings with 8, 16, and 32-bit codeunit sizes
* Correctly sets the NO_CHECK_UTF flag based on the string type

It is working on both the release version (v0.6.2) and the latest master (v0.7.0-DEV).

This uses a `R"..."` macro, or `RegexStr` constructor, instead of `r"..."` and `Regex` as in Base.

Some changes might be needed in Base to make it work with the `r"..."` regex string macro and `Regex` type, because there are some fields missing that would be needed to handle arbitrary abstract string types).
