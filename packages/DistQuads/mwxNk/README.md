# DistQuads

[![Build Status](https://travis-ci.org/pkofod/DistQuads.jl.svg?branch=master)](https://travis-ci.org/pkofod/DistQuads.jl)

[![Coverage Status](https://coveralls.io/repos/pkofod/DistQuads.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/pkofod/DistQuads.jl?branch=master)

[![codecov.io](http://codecov.io/github/pkofod/DistQuads.jl/coverage.svg?branch=master)](http://codecov.io/github/pkofod/DistQuads.jl?branch=master)

# What

Evaluating the expected value of functions of random variables requires numerical
integration. There are many ways to do this, but a very popular approach is to
transform the integral evaluation into a weighed sum of function evaluations at
N values, often called nodes, useing so-called Gaussian quadrature.

This package builds on top of the Distributions.jl package, and it provides a simple
interface to generate Guassian quadrature weights and nodes for numerical integration
as explained above.

```julia
julia> using Distributions, DistQuads

julia> bd = Beta(1.4, 5.4)
Distributions.Beta{Float64}(α=1.4, β=5.4)

julia> dq = DistQuad(bd)
DistQuads.DistQuad([0.00185197,0.00773162,0.017613,0.0314164,0.0490303,0.0703119,0.095089,0.123161,0.1543,0.188255  …  0.740476,0.779219,0.815718,0.849678,0.880826,0.90891,0.933707,0.955022,0.972705,0.986694],[0.00387997,0.013685,0.0273551,0.0429761,0.0586422,0.0726105,0.0834732,0.0902888,0.0926473,0.0906605  …  0.00117028,0.000555584,0.000239261,9.17104e-5,3.04716e-5,8.44413e-6,1.83878e-6,2.84652e-7,2.58301e-8,8.47448e-10],Distributions.Beta{Float64}(α=1.4, β=5.4))

julia> mean(dq)
0.20588235294117635

julia> mean(bd)
0.20588235294117643

julia> var(dq)
0.020960873036997594

julia> var(bd)
0.020960873036997597

```
