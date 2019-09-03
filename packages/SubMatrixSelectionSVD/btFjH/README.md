# SubMatrixSelectionSVD

[![Build Status](https://travis-ci.org/rasmushenningsson/SubMatrixSelectionSVD.jl.svg?branch=master)](https://travis-ci.org/rasmushenningsson/SubMatrixSelectionSVD.jl)
[![Coverage Status](https://coveralls.io/repos/rasmushenningsson/SubMatrixSelectionSVD.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/rasmushenningsson/SubMatrixSelectionSVD.jl?branch=master)
[![codecov.io](http://codecov.io/github/rasmushenningsson/SubMatrixSelectionSVD.jl/coverage.svg?branch=master)](http://codecov.io/github/rasmushenningsson/SubMatrixSelectionSVD.jl?branch=master)


[SubMatrix Selection Singular Value Decomposition](http://arxiv.org/abs/1710.08144).

## Installation
```julia
using Pkg
Pkg.add("SubMatrixSelectionSVD")
```

## Example
```julia
using SubMatrixSelectionSVD, LinearAlgebra, DataFrames, Gadfly

# Create matrices with orthonormal columns
function randorthonormal(P::Integer, N::Integer)
    @assert P≥N
    O = zeros(P,N)
    for k=1:N
        x = randn(P)
        x -= O[:,1:k-1]*(O[:,1:k-1]'x)
        O[:,k] = x/norm(x)
    end
    O
end

# Create data matrix corrupted by noise
P = 1000
N = 40
d = 4
u = zeros(P,d)
u[1:100,1:2]   = randorthonormal(100,2)
u[101:200,3:4] = randorthonormal(100,2)
s = [10,8,5,4] # singular values
v = randorthonormal(N,d)
X = u*Diagonal(s)*v' + 0.1*randn(P,N).*rand(P) # different strength of noise for different variables

# Compute the SMSSVD of X
σThresholds = 10 .^ range(-2,stop=0,length=100)
U,Σ,V,ps,signalDimensions = smssvd(X, d, σThresholds)

# Projection Score Plot
df = DataFrame(Sigma=repeat(σThresholds',d,1)[:], ProjectionScore=ps[:], NbrDims=repeat(1:d,1,length(σThresholds))[:])
coords = Coord.cartesian(xmin=log10(σThresholds[1]), xmax=log10(σThresholds[end]), ymin=0)
plot(df,x=:Sigma,y=:ProjectionScore,color=:NbrDims,Geom.line,coords,Scale.x_log10,Guide.xlabel("σ Threshold"),Guide.ylabel("Projection Score"),Guide.colorkey(title="Dimension"),Guide.title("Projection Score"))
```
