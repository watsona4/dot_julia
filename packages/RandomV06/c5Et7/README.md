[![Build Status](https://travis-ci.org/danspielman/RandomV06.jl.svg?branch=master)](https://travis-ci.org/danspielman/RandomV06.jl)

# RandomV06

This is a copy of random.jl from version 0.6 of Julia that has been adapted to run in Julia 0.7.  The file was retrieved from https://github.com/JuliaLang/julia/blob/v0.6.4/base/random.jl, and hacked until it stopped producing errors or warnings in Julia 0.7.

The motivation is the observation that at least some parts of the pseudorandom generator from Julia 0.7, and we sometimes want to reproduce tests and examples generated in Julia 0.6.  Here are examples from Julia 0.6 and 0.7 that give different behavior:

~~~julia
julia> VERSION
v"0.6.4"

julia> srand(1); rand(1:10,3)
3-element Array{Int64,1}:
  9
  7
 10
~~~

~~~julia
julia> VERSION
v"0.7.0-beta2.0"

julia> srand(1); rand(1:10,3)
3-element Array{Int64,1}:
 3
 8
 2
~~~

# Installation

~~~julia
(v0.7) pkg> add https://github.com/danspielman/RandomV06.jl

~~~



# Using

After obtaining the package, just type `using RandomV06`.  You can then access the old functions under this module, like this:

~~~julia
julia> using RandomV06

julia> RandomV06.srand(1); RandomV06.rand(1:10,3)
3-element Array{Int64,1}:
  9
  7
 10
~~~

The module RandomV06 has its own version of `GLOBAL_RNG `, so it does not interact with the standard one:

~~~julia
julia> srand(1);

julia> RandomV06.srand(1);

julia> rand(1:10,3)
3-element Array{Int64,1}:
 3
 8
 2

julia> RandomV06.rand(1:10,3)
3-element Array{Int64,1}:
  9
  7
 10
~~~



To facilitate writing code that can use either version, we have created variants of all of the functions in Random that have `_ver` appended.  One can then select the version you want by calling one of these with one of the constants `RandomV06.V06`, `RandomV06.07` or `RandomV06.Vcur` as the first argument.

~~~julia
julia> const Vcur = RandomV06.Vcur;

julia> const V6 = RandomV06.V06;

julia> srand_ver(V6, 1); 

julia> srand_ver(Vcur, 1);

julia> rand_ver(V6, 1:10, 3)
3-element Array{Int64,1}:
  9
  7
 10

julia> rand_ver(Vcur, 1:10, 3)
3-element Array{Int64,1}:
 3
 8
 2
~~~



# Bugs

RandomV06 does not handle `randjump`.

