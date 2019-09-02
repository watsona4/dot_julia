# Hilbert.jl

master: ![master](https://travis-ci.com/fpreiswerk/Hilbert.jl.svg?branch=master)
v1.0: ![v1.0](https://travis-ci.com/fpreiswerk/Hilbert.jl.svg?branch=v1.0)
    
Compute the Hilbert transform of a signal in Julia.

```julia
julia> using Hilbert

julia> signal = [1 2 3 4]
1×4 Array{Int64,2}:
 1  2  3  4

julia> hilbert(signal)
1×4 Array{Complex{Float64},2}:
 1.0+1.0im  2.0-1.0im  3.0-1.0im  4.0+1.0im
```
