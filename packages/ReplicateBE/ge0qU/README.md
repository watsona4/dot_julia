# ReplicateBE.jl
Mixed model solution for replicate designed bioequivalence study.

[![Build Status](https://api.travis-ci.com/PharmCat/ReplicateBE.jl.svg?branch=master)](https://travis-ci.com/PharmCat/ReplicateBE.jl)


Install:
```
using Pkg; Pkg.add("ReplicateBE")
```
or:
```
using Pkg; Pkg.clone("https://github.com/PharmCat/ReplicateBE.jl.git")
```

Using:
```
using ReplicateBE
be = ReplicateBE.rbe(df, dvar = :var, subject = :subject, formulation = :formulation, period = :period, sequence = :sequence);
ci = confint(be, 0.1)
```
Where:

- dvar::Symbol - dependent variable;
- subject::Symbol - subject;
- formulation::Symbol - formulation/drug;
- period::Symbol - study period;
- sequence::Symbol - sequence;

Get results (as vectors):

```
be.β            #For β
be.se           #For SE
be.reml         #REML value
be.df           #Degree of freedom
be.f            #F Statistics
```

Other:

```
struct RBE
    model::ModelFrame
    factors::Array{Symbol, 1}
    β::Array{Float64, 1}
    θ0::Array{Float64, 1}
    θ::Array{Float64, 1}
    reml::Float64
    se::Array{Float64, 1}
    f::Array{Float64, 1}
    df::Array{Float64, 1}
    df2::Float64
    R::Array{Matrix{Float64},1}
    V::Array{Matrix{Float64},1}
    G::Matrix{Float64}
    C::Matrix{Float64}
    A::Matrix{Float64}              #asymptotic variance-covariance matrix ofb θ
    H::Matrix{Float64}
    X::Matrix
    Z::Matrix
    Xv::Array{Matrix{Float64},1}
    Zv::Array{Matrix{Float64},1}
    yv::Array{Array{Float64, 1},1}
    detH::Float64
    preoptim::Optim.MultivariateOptimizationResults
    optim::Optim.MultivariateOptimizationResults
end
```

# Methods

```
StatsBase.confint(obj::RBE, alpha::Float64; expci::Bool = false, inv::Bool = false)
```

* obj::RBE - bioequivalence struct;
* alpha::Float64 - alpha;
* expci::Bool - exp(ci)
* inv::Bool - β = -β

```
reml2(obj::RBE, θ::Array{Float64, 1})
```

Return -2REML for vector θ.

```
contrast(obj::RBE, L::Matrix{T}) where T <: Real
```

Return F for L vector.

```
lsm(obj::RBE, L::Matrix{T}) where T <: Real
```

Return mean & se for L vector.

```
emm(obj::RBE, fm, lm)
```

Return marginal means.

fm - factor map;
lm - level map.

```
lmean(obj::RBE)
```

Return L vector for general mean.

Author: Vladimir Arnautov aka PharmCat

Copyright © 2019 Vladimir Arnautov aka PharmCat <mail@pharmcat.net>
