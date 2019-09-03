# Unicode_Entities: Support for using Unicode entity names for characters

| **Info** | **Windows** | **Linux & MacOS** | **Package Evaluator** | **CodeCov** | **Coveralls** |
|:------------------:|:------------------:|:---------------------:|:-----------------:|:---------------------:|:-----------------:|
| [![][license-img]][license-url] | [![][app-s-img]][app-s-url] | [![][travis-s-img]][travis-url] | [![][pkg-s-img]][pkg-s-url] | [![][codecov-img]][codecov-url] | [![][coverall-s-img]][coverall-s-url]
| [![][gitter-img]][gitter-url] | [![][app-m-img]][app-m-url] | [![][travis-m-img]][travis-url] | [![][pkg-m-img]][pkg-m-url] | [![][codecov-img]][codecov-url] | [![][coverall-m-img]][coverall-m-url]

[license-img]:  http://img.shields.io/badge/license-MIT-brightgreen.svg?style=flat
[license-url]:  LICENSE.md

[gitter-img]:   https://badges.gitter.im/Join%20Chat.svg
[gitter-url]:   https://gitter.im/JuliaString/Lobby?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge

[travis-url]:   https://travis-ci.org/JuliaString/Unicode_Entities.jl
[travis-s-img]: https://travis-ci.org/JuliaString/Unicode_Entities.jl.svg
[travis-m-img]: https://travis-ci.org/JuliaString/Unicode_Entities.jl.svg?branch=master

[app-s-url]:    https://ci.appveyor.com/project/ScottPJones/unicode-entities-jl
[app-m-url]:    https://ci.appveyor.com/project/ScottPJones/unicode-entities-jl/branch/master
[app-s-img]:    https://ci.appveyor.com/api/projects/status/c1luci97ry8fxdt7?svg=true
[app-m-img]:    https://ci.appveyor.com/api/projects/status/c1luci97ry8fxdt7/branch/master?svg=true

[pkg-s-url]:    http://pkg.julialang.org/detail/Unicode_Entities
[pkg-m-url]:    http://pkg.julialang.org/detail/Unicode_Entities
[pkg-s-img]:    http://pkg.julialang.org/badges/Unicode_Entities_0.6.svg
[pkg-m-img]:    http://pkg.julialang.org/badges/Unicode_Entities_0.7.svg

[codecov-url]:  https://codecov.io/gh/JuliaString/Unicode_Entities.jl
[codecov-img]:  https://codecov.io/gh/JuliaString/Unicode_Entities.jl/branch/master/graph/badge.svg

[coverall-s-url]: https://coveralls.io/github/JuliaString/Unicode_Entities.jl
[coverall-m-url]: https://coveralls.io/github/JuliaString/Unicode_Entities.jl?branch=master
[coverall-s-img]: https://coveralls.io/repos/github/JuliaString/Unicode_Entities.jl/badge.svg
[coverall-m-img]: https://coveralls.io/repos/github/JuliaString/Unicode_Entities.jl/badge.svg?branch=master

Unicode_Entities.jl
====================================================================

This builds tables for looking up Unicode entity names and returning the Unicode character(s),
looking up a character or pair of characters and finding Unicode entity names that return it/them,
and finding all of the Unicode name completions for a particular string, if any.
