# TropicalSemiring
[![Build Status](https://travis-ci.org/saschatimme/TropicalSemiring.jl.svg?branch=master)](https://travis-ci.org/saschatimme/TropicalSemiring.jl)
![Codecov branch][codecov-img]

This small package defines the tropical semi-ring with either the max or min convention.
With the max convention this is the semi-ring (ℝ ∪ {-∞}, ⊕, ⊙) where
⊕ is the usual multiplication and ⊙ is the usual maximum.
With the min convention this is the semi-ring (ℝ ∪ {∞}, ⊕, ⊙) where
⊕ is the usual multiplication and ⊙ is the usual minimum.
This corresponding Julia type is
```julia
Trop{MM<:Union{Min, Max}, T<:Real} <: Number
```

For the tropical addition and multiplication the usual `+` and `*` are overloaded.
```julia
julia> Trop{Max}(2) + Trop{Max}(3) == Trop{Max}(3)
true
julia> Trop{Min}(2) + Trop{Min}(3) == Trop{Min}(2)
true
julia> Trop{Min}(2) * Trop{Min}(3) == Trop{Min}(5)
true
julia> Trop{Max}(2) * Trop{Max}(3) == Trop{Max}(5)
true
```
Note that by default we use the **max convention**, i.e.,
```julia
julia> Trop(2) + Trop(3)
3
```

You can construct ±∞ by using the `inf` method
```julia
julia> inf(Max) isa Trop{Max}
true
julia> Trop{Max}(2) + inf(Max)
-∞
julia> inf(Min) isa Trop{Min}
true
julia> Trop{Min}(2) + inf(Min)
∞
# By default we have again the max convention
julia> inf() isa Trop{Max}
true
```

[codecov-img]: http://codecov.io/github/saschatimme/TropicalSemiring.jl/coverage.svg?branch=master
[codecov-url]: http://codecov.io/github/saschatimme/TropicalSemiring.jl?branch=master
