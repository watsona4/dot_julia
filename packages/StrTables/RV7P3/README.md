# StrTables:
## Support for creating packed tables of strings and save/load simple tables with values

| **Info** | **Windows** | **Linux & MacOS** | **Package Evaluator** | **CodeCov** | **Coveralls** |
|:------------------:|:------------------:|:---------------------:|:-----------------:|:---------------------:|:-----------------:|
| [![][license-img]][license-url] | [![][app-s-img]][app-s-url] | [![][travis-s-img]][travis-url] | [![][pkg-s-img]][pkg-s-url] | [![][codecov-img]][codecov-url] | [![][coverall-s-img]][coverall-s-url]
| [![][gitter-img]][gitter-url] | [![][app-m-img]][app-m-url] | [![][travis-m-img]][travis-url] | [![][pkg-m-img]][pkg-m-url] | [![][codecov-img]][codecov-url] | [![][coverall-m-img]][coverall-m-url]

[license-img]:  http://img.shields.io/badge/license-MIT-brightgreen.svg?style=flat
[license-url]:  LICENSE.md

[gitter-img]:   https://badges.gitter.im/Join%20Chat.svg
[gitter-url]:   https://gitter.im/JuliaString/Lobby?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge

[travis-url]:   https://travis-ci.org/JuliaString/StrTables.jl
[travis-s-img]: https://travis-ci.org/JuliaString/StrTables.jl.svg
[travis-m-img]: https://travis-ci.org/JuliaString/StrTables.jl.svg?branch=master

[app-s-url]:    https://ci.appveyor.com/project/ScottPJones/strtables-jl
[app-m-url]:    https://ci.appveyor.com/project/ScottPJones/strtables-jl/branch/master
[app-s-img]:    https://ci.appveyor.com/api/projects/status/ekt5t6nt8g0cqhjb?svg=true
[app-m-img]:    https://ci.appveyor.com/api/projects/status/ekt5t6nt8g0cqhjb/branch/master?svg=true

[pkg-s-url]:    http://pkg.julialang.org/detail/StrTables
[pkg-m-url]:    http://pkg.julialang.org/detail/StrTables
[pkg-s-img]:    http://pkg.julialang.org/badges/StrTables_0.6.svg
[pkg-m-img]:    http://pkg.julialang.org/badges/StrTables_0.7.svg

[codecov-url]:  https://codecov.io/gh/JuliaString/StrTables.jl
[codecov-img]:  https://codecov.io/gh/JuliaString/StrTables.jl/branch/master/graph/badge.svg

[coverall-s-url]: https://coveralls.io/github/JuliaString/StrTables.jl
[coverall-m-url]: https://coveralls.io/github/JuliaString/StrTables.jl?branch=master
[coverall-s-img]: https://coveralls.io/repos/github/JuliaString/StrTables.jl/badge.svg
[coverall-m-img]: https://coveralls.io/repos/github/JuliaString/StrTables.jl/badge.svg?branch=master

This is used to build compact tables that can be used to create things like entity mappings
It also provides simple load/save functions to save and then load string tables along with
other simple types (UInt8..UInt64, Int8..Int64, Float32, Float64, vectors of those types,
and String) to/from a file.

Doing so can eliminate a lot of JITing time needed just to parse and then create a table from
Julia source, and when Julia can be used to build executables, allows the tables to be updated
without recompiling the executable.
