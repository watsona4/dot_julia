# Emoji_Entities: Support for using Emoji names for characters

| **Info** | **Windows** | **Linux & MacOS** | **Package Evaluator** | **CodeCov** | **Coveralls** |
|:------------------:|:------------------:|:---------------------:|:-----------------:|:---------------------:|:-----------------:|
| [![][license-img]][license-url] | [![][app-s-img]][app-s-url] | [![][travis-s-img]][travis-url] | [![][pkg-s-img]][pkg-s-url] | [![][codecov-img]][codecov-url] | [![][coverall-s-img]][coverall-s-url]
| [![][gitter-img]][gitter-url] | [![][app-m-img]][app-m-url] | [![][travis-m-img]][travis-url] | [![][pkg-m-img]][pkg-m-url] | [![][codecov-img]][codecov-url] | [![][coverall-m-img]][coverall-m-url]

[license-img]:  http://img.shields.io/badge/license-MIT-brightgreen.svg?style=flat
[license-url]:  LICENSE.md

[gitter-img]:   https://badges.gitter.im/Join%20Chat.svg
[gitter-url]:   https://gitter.im/JuliaString/Lobby?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge

[travis-url]:   https://travis-ci.org/JuliaString/Emoji_Entities.jl
[travis-s-img]: https://travis-ci.org/JuliaString/Emoji_Entities.jl.svg
[travis-m-img]: https://travis-ci.org/JuliaString/Emoji_Entities.jl.svg?branch=master

[app-s-url]:    https://ci.appveyor.com/project/ScottPJones/emoji-entities-jl
[app-m-url]:    https://ci.appveyor.com/project/ScottPJones/emoji-entities-jl/branch/master
[app-s-img]:    https://ci.appveyor.com/api/projects/status/4p6o3reehca95put?svg=true
[app-m-img]:    https://ci.appveyor.com/api/projects/status/4p6o3reehca95put/branch/master?svg=true

[pkg-s-url]:    http://pkg.julialang.org/detail/Emoji_Entities
[pkg-m-url]:    http://pkg.julialang.org/detail/Emoji_Entities
[pkg-s-img]:    http://pkg.julialang.org/badges/Emoji_Entities_0.6.svg
[pkg-m-img]:    http://pkg.julialang.org/badges/Emoji_Entities_0.7.svg

[codecov-url]:  https://codecov.io/gh/JuliaString/Emoji_Entities.jl
[codecov-img]:  https://codecov.io/gh/JuliaString/Emoji_Entities.jl/branch/master/graph/badge.svg

[coverall-s-url]: https://coveralls.io/github/JuliaString/Emoji_Entities.jl
[coverall-m-url]: https://coveralls.io/github/JuliaString/Emoji_Entities.jl?branch=master
[coverall-s-img]: https://coveralls.io/repos/github/JuliaString/Emoji_Entities.jl/badge.svg
[coverall-m-img]: https://coveralls.io/repos/github/JuliaString/Emoji_Entities.jl/badge.svg?branch=master

Emoji_Entities.jl
====================================================================

This builds tables for looking up Emoji names and returning the Unicode character(s),
looking up a character or pair of characters and finding Emoji names that return it/them,
and finding all of the Emoji name completions for a particular string, if any.
