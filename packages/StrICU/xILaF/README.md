# StrICU: International Components for Unicode (ICU) wrapper for Julia
====================================================================

Julia wrapper for the
[International Components for Unicode (ICU) libraries](http://site.icu-project.org/).

| **Info** | **Windows** | **Linux & MacOS** | **Package Evaluator** | **CodeCov** | **Coveralls** |
|:------------------:|:------------------:|:---------------------:|:-----------------:|:---------------------:|:-----------------:|
| [![][license-img]][license-url] | [![][app-s-img]][app-s-url] | [![][travis-s-img]][travis-url] | [![][pkg-s-img]][pkg-s-url] | [![][codecov-img]][codecov-url] | [![][coverall-s-img]][coverall-s-url]
| [![][gitter-img]][gitter-url] | [![][app-m-img]][app-m-url] | [![][travis-m-img]][travis-url] | [![][pkg-m-img]][pkg-m-url] | [![][codecov-img]][codecov-url] | [![][coverall-m-img]][coverall-m-url]

[license-img]:  http://img.shields.io/badge/license-MIT-brightgreen.svg?style=flat
[license-url]:  LICENSE.md

[gitter-img]:   https://badges.gitter.im/Join%20Chat.svg
[gitter-url]:   https://gitter.im/JuliaString/Lobby?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge

[travis-url]:   https://travis-ci.org/JuliaString/StrICU.jl
[travis-s-img]: https://travis-ci.org/JuliaString/StrICU.jl.svg
[travis-m-img]: https://travis-ci.org/JuliaString/StrICU.jl.svg?branch=master

[app-s-url]:    https://ci.appveyor.com/project/ScottPJones/stricu-jl
[app-m-url]:    https://ci.appveyor.com/project/ScottPJones/stricu-jl/branch/master
[app-s-img]:    https://ci.appveyor.com/api/projects/status/kcqvq7e2k3o5rn6g?svg=true
[app-m-img]:    https://ci.appveyor.com/api/projects/status/kcqvq7e2k3o5rn6g/branch/master?svg=true

[pkg-s-url]:    http://pkg.julialang.org/detail/StrICU
[pkg-m-url]:    http://pkg.julialang.org/detail/StrICU
[pkg-s-img]:    http://pkg.julialang.org/badges/StrICU_0.6.svg
[pkg-m-img]:    http://pkg.julialang.org/badges/StrICU_0.7.svg

[codecov-url]:  https://codecov.io/gh/JuliaString/StrICU.jl
[codecov-img]:  https://codecov.io/gh/JuliaString/StrICU.jl/branch/master/graph/badge.svg

[coverall-s-url]: https://coveralls.io/github/JuliaString/StrICU.jl
[coverall-m-url]: https://coveralls.io/github/JuliaString/StrICU.jl?branch=master
[coverall-s-img]: https://coveralls.io/repos/github/JuliaString/StrICU.jl/badge.svg
[coverall-m-img]: https://coveralls.io/repos/github/JuliaString/StrICU.jl/badge.svg?branch=master

This is a new wrapper for the ICU library, designed to work on Julia v0.6 and above,
using the [Strs.jl](http://github.com/JuliaString/Strs.jl) package to provide support for UTF-16 encoded strings.
The API has been redesigned to not pollute the namespace and to try to be a bit more "Julian"
