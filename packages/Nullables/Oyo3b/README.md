# Nullables

[![Travis CI](https://travis-ci.org/JuliaArchive/Nullables.jl.svg?branch=master)](https://travis-ci.org/JuliaArchive/Nullables.jl) [![AppVeyor](https://ci.appveyor.com/api/projects/status/kisn3iwg0awcucnm?svg=true)](https://ci.appveyor.com/project/nalimilan/nullables-jl) [![coveralls.io](https://coveralls.io/repos/JuliaArchive/Nullables.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/JuliaArchive/Nullables.jl?branch=master) [![codecov.io](http://codecov.io/github/JuliaArchive/Nullables.jl/coverage.svg?branch=master)](http://codecov.io/github/JuliaArchive/Nullables.jl?branch=master)

This package provides the `Nullable` type from Julia 0.6, which was removed in
subsequent versions. It also defines the `unsafe_get` and `isnull` functions, and all
methods previously implemented in Julia Base: `get`, `eltype`, `convert`, `promote`,
`show`, `map`, `broadcast`, `filter`, `isequal`, `isless` and `hash`.

The definitions of the above types and functions are conditional on the version of Julia
being used so that you can do `using Nullables` unconditionally and be guaranteed that
`Nullable` will behave as it did in Julia 0.6 in later releases.
