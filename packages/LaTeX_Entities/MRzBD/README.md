# LaTeX_Entities
## Support for using LaTeX entity names for characters

| **Info** | **Windows** | **Linux & MacOS** | **Package Evaluator** | **CodeCov** | **Coveralls** |
|:------------------:|:------------------:|:---------------------:|:-----------------:|:---------------------:|:-----------------:|
| [![][license-img]][license-url] | [![][app-s-img]][app-s-url] | [![][travis-s-img]][travis-url] | [![][pkg-s-img]][pkg-s-url] | [![][codecov-img]][codecov-url] | [![][coverall-s-img]][coverall-s-url]
| [![][gitter-img]][gitter-url] | [![][app-m-img]][app-m-url] | [![][travis-m-img]][travis-url] | [![][pkg-m-img]][pkg-m-url] | [![][codecov-img]][codecov-url] | [![][coverall-m-img]][coverall-m-url]

[license-img]:  http://img.shields.io/badge/license-MIT-brightgreen.svg?style=flat
[license-url]:  LICENSE.md

[gitter-img]:   https://badges.gitter.im/Join%20Chat.svg
[gitter-url]:   https://gitter.im/JuliaString/Lobby?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge

[travis-url]:   https://travis-ci.org/JuliaString/LaTeX_Entities.jl
[travis-s-img]: https://travis-ci.org/JuliaString/LaTeX_Entities.jl.svg
[travis-m-img]: https://travis-ci.org/JuliaString/LaTeX_Entities.jl.svg?branch=master

[app-s-url]:    https://ci.appveyor.com/project/ScottPJones/latex-entities-jl
[app-m-url]:    https://ci.appveyor.com/project/ScottPJones/latex-entities-jl/branch/master
[app-s-img]:    https://ci.appveyor.com/api/projects/status/ok2sdq4u5xwlc6b0?svg=true
[app-m-img]:    https://ci.appveyor.com/api/projects/status/ok2sdq4u5xwlc6b0/branch/master?svg=true

[pkg-s-url]:    http://pkg.julialang.org/detail/LaTeX_Entities
[pkg-m-url]:    http://pkg.julialang.org/detail/LaTeX_Entities
[pkg-s-img]:    http://pkg.julialang.org/badges/LaTeX_Entities_0.6.svg
[pkg-m-img]:    http://pkg.julialang.org/badges/LaTeX_Entities_0.7.svg

[codecov-url]:  https://codecov.io/gh/JuliaString/LaTeX_Entities.jl
[codecov-img]:  https://codecov.io/gh/JuliaString/LaTeX_Entities.jl/branch/master/graph/badge.svg

[coverall-s-url]: https://coveralls.io/github/JuliaString/LaTeX_Entities.jl
[coverall-m-url]: https://coveralls.io/github/JuliaString/LaTeX_Entities.jl?branch=master
[coverall-s-img]: https://coveralls.io/repos/github/JuliaString/LaTeX_Entities.jl/badge.svg
[coverall-m-img]: https://coveralls.io/repos/github/JuliaString/LaTeX_Entities.jl/badge.svg?branch=master


This builds tables for looking up LaTeX names and returning the Unicode character(s),
looking up a character or pair of characters and finding LaTeX names that return it/them,
and finding all of the LaTeX name completions for a particular string, if any.
