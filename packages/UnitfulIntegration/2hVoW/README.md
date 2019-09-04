# UnitfulIntegration

[![Build Status](https://travis-ci.org/ajkeller34/UnitfulIntegration.jl.svg?branch=master)](https://travis-ci.org/ajkeller34/UnitfulIntegration.jl)
[![Coverage Status](https://coveralls.io/repos/ajkeller34/UnitfulIntegration.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/ajkeller34/UnitfulIntegration.jl?branch=master)
[![codecov.io](http://codecov.io/github/ajkeller34/UnitfulIntegration.jl/coverage.svg?branch=master)](http://codecov.io/github/ajkeller34/UnitfulIntegration.jl?branch=master)

This package enables integration of physical quantity-valued functions, using
the Quantity types implemented in [Unitful.jl](https://github.com/ajkeller34/Unitful.jl).

This package currently supports [QuadGK.jl](https://github.com/JuliaMath/QuadGK.jl),
which was originally in Julia Base. We do not support QuadGK as implemented in Julia 0.5.
To use this package with Julia 0.5, you need to install the QuadGK package and
qualify all invocations of QuadGK functions with the module name (e.g.
`import QuadGK; QuadGK.quadgk(...)`).

PRs for other integration packages are welcome.
