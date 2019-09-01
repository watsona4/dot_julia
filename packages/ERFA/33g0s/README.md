# ERFA.jl

*Julia wrapper for [liberfa](https://github.com/liberfa/erfa)*

[![Build Status Unix][travis-badge]][travis-url] [![Build Status Windows][av-badge]][av-url] [![Coveralls][coveralls-badge]][coveralls-url] [![Codecov][codecov-badge]][codecov-url] [![Docs Stable][docs-badge-stable]][docs-url-stable] [![Docs Latest][docs-badge-dev]][docs-url-dev]


## Installation

```julia
julia> Pkg.add("ERFA")
```

## Example

```julia
julia> using ERFA

julia> u1,u2 = ERFA.dtf2d("UTC", 2010, 7, 24, 11, 18, 7.318)
(2.4554015e6,0.47091803240740737)

julia> a1,a2 = ERFA.utctai(u1, u2)
(2.4554015e6,0.4713115509259259)

julia> t1,t2 = ERFA.taitt(a1, a2)
(2.4554015e6,0.4716840509259259)

julia> ERFA.d2dtf("tt", 3, t1, t2)
(2010,7,24,11,19,13,502)
```

## Documentation

Please refer to the [documentation][docs-url-stable] for additional
information.

[travis-badge]: https://travis-ci.org/JuliaAstro/ERFA.jl.svg?branch=master
[travis-url]: https://travis-ci.org/JuliaAstro/ERFA.jl
[av-badge]: https://img.shields.io/appveyor/ci/kbarbary/erfa-jl.svg?label=windows
[av-url]: https://ci.appveyor.com/project/kbarbary/erfa-jl/branch/master
[coveralls-badge]: https://coveralls.io/repos/github/JuliaAstro/ERFA.jl/badge.svg?branch=master
[coveralls-url]: https://coveralls.io/github/JuliaAstro/ERFA.jl?branch=master
[codecov-badge]: https://codecov.io/github/JuliaAstro/ERFA.jl/coverage.svg?branch=master
[codecov-url]: https://codecov.io/github/JuliaAstro/ERFA.jl?branch=master
[docs-badge-dev]: https://img.shields.io/badge/docs-dev-blue.svg
[docs-url-dev]: https://juliaastro.github.io/ERFA.jl/dev
[docs-badge-stable]: https://img.shields.io/badge/docs-stable-blue.svg
[docs-url-stable]: https://juliaastro.github.io/ERFA.jl/stable
