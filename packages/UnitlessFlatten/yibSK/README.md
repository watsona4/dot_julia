# UnitlessFlatten

[![Build Status](https://travis-ci.org/rafaqz/UnitlessFlatten.jl.svg?branch=master)](https://travis-ci.org/rafaqz/UnitlessFlatten.jl)
[![Build status](https://ci.appveyor.com/api/projects/status/dpf055yo50y21g1v?svg=true)](https://ci.appveyor.com/project/rafaqz/unitlessflatten-jl)
[![codecov.io](http://codecov.io/github/rafaqz/UnitlessFlatten.jl/coverage.svg?branch=master)](http://codecov.io/github/rafaqz/UnitlessFlatten.jl?branch=master)

UnitlessFlatten.jl extends [Flatten.jl](https://github.com/rafaqz/Flatten.jl) to
provide struct flattening that strips units. This can be far more efficient than
simply stripping them afterwards as it improves type stability.

Simply use as you would use Flatten.jl, and types will be flattened to Unitless tuples 
or vectors, and reconstructed including the original units.
