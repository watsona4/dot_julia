#=
This file is part of the RandomizedPropertyTest.jl project.

Copyright © 2019  Lukas Himbert

RandomizedPropertyTest.jl is free software:
you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, version 3 of the License.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program.
If not, see <https://www.gnu.org/licenses/>.
=#


"""
    RandomizedPropertyTest

Performs randomized property tests (also known as specification tests) of your programs or functions.

For usage information, see `@quickcheck`.
"""
module RandomizedPropertyTest

using Random: MersenneTwister, AbstractRNG, randexp
import Base.product
import Base.Iterators.flatten
using Logging: @warn

export @quickcheck


"""
    @quickcheck [n=nexpr] expr (vartuple :: T) [...]

Check whether the property expressed by `expr` holds for variables `vartuple...` of type `T`.
Multiple such variable declarations may be given.
Returns `false` if a counterexample was found, `true` otherwise.
It should be noted that a result of `true` does not constitute proof of the property.

`nexpr` is the number of pseudorandom inputs used to examine the veracity of the property.
It has no effect on special cases, which are always checked.
To check only special cases, you may set `nexpr` to zero.

For reproducibility of counterexamples, inputs are chosen pseudorandomly with a fixed seed.
Instead of running `@quickcheck` multiple times to be more certain of the property you wish to verify, run it once with a larger `n`.

To use `@quickcheck` with custom data types or custom distributions of builtin datatypes, see `generate` and `specialcases`.
Some data types for custom distributions (e.g. `Range{T,a,b}`) are predefined in this module.

Examples
--------

Check the associativity of `+` for Ints:
```jldoctest
julia> @quickcheck (a+b == b+a) (a :: Int) (b :: Int)
true
```

The same test with alternative syntax and a larger number of tests:
```jldoctest
julia> @quickcheck n=10^6 (a+b == b+a) ((a, b) :: Int)
true
```

On the other hand, a test of the associativity of double-precision floats fails, even if only finite values are allowed (no `NaN`, ±`Inf`):
```jldoctest
julia> @quickcheck (a+(b+c) == (a+b)+c || !all(isfinite, (a,b,c))) ((a,b,c) :: Float64)
┌ Warning: Property `a + (b + c) == (a + b) + c || (any(isnan, (a, b, c)) || any(isinf, (a, b, c)))` does not hold for (a = 0.3333333333333333, b = 1.0, c = 1.0).
└ @ RandomizedPropertyTest ~/store/zeug/public/RandomizedPropertyTest/src/RandomizedPropertyTest.jl:119
false
```

Test an addition theorem of `sin` over one period:
```jldoctest
julia> @quickcheck (sin(α - β) ≈ sin(α) * cos(β) - cos(α) * sin(β)) ((α, β) :: Range{Float64, 0, 2π})
true
```
"""
macro quickcheck(args...)
  names = Symbol[]
  types = []

  length(args) >= 2 || error("Use as @quickcheck [n=nexpr] expr type [...]")

  if args[1] isa Expr && args[1].head == :(=) && args[1].args[1] == :n
    nexpr = esc(args[1].args[2])
    args = args[2:length(args)]
    length(args) >= 2 || error("Use as @quickcheck [n=nexpr] expr type [...]")
  else
    nexpr = 10^4
  end

  expr = args[1]
  vartypes = args[2:length(args)]

  length(vartypes) > 0 || error("No variable declared. Please use @test to test properties with no free variables.")

  for e in vartypes
    e isa Expr && e.head == :(::) || error("Invalid variable declaration `$e`.")
    if e.args[1] isa Symbol
      newsymbols = Symbol[e.args[1]]
    elseif e.args[1].head == :tuple && all(x->x isa Symbol, e.args[1].args)
      newsymbols = e.args[1].args
    else
      error("Invalid variable declaration `$e`.")
    end
    all(x -> !(x in names), newsymbols) || error("Duplicate declaration of $(e.args[1]).")
    for symb in newsymbols
      push!(names, symb)
      push!(types, e.args[2])
    end
  end

  nametuple = Expr(:tuple, names...)
  typetuple = esc(Expr(:tuple, types...)) # escaping is required for user-provided types
  exprstr = let io = IOBuffer(); print(io, expr); seek(io, 0); read(io, String); end
  namestrs = [String(n) for n in names]
  fexpr = esc(Expr(:(->), nametuple, expr)) # escaping is required for global (and other) variables in the calling scope

  return quote
    do_quickcheck($fexpr, $exprstr, $namestrs, $typetuple, $nexpr)
  end
end


function do_quickcheck(f :: Function, exprstr, varnames, types :: NTuple{N,DataType}, n :: Integer) where {N}
  rng = MersenneTwister(0)
  for vars in specialcases(types)
    do_quickcheck(f, exprstr, varnames, vars) || return false
  end
  for _ in 1:n
    vars = generate(rng, types)
    do_quickcheck(f, exprstr, varnames, vars) || return false
  end
  return true
end


function do_quickcheck(f :: Function, exprstr, varnames, vars)
  try
    if !f(vars...)
      if length(varnames) == 1
        x = Expr(:(=), Symbol(varnames[1]), vars[1])
      else
        x = Expr(:tuple, (Expr(:(=), n, v) for (n, v) in zip(map(Symbol, varnames), vars))...)
      end
      @warn "Property `$exprstr` does not hold for $x."
      return false
    end
  catch exception
    if length(varnames) == 1
      x = Expr(:(=), Symbol(varnames[1]), vars[1])
    else
      x = Expr(:tuple, (Expr(:(=), n, v) for (n, v) in zip(map(Symbol, varnames), vars))...)
    end
    @warn "Property `$exprstr` does not hold for $x."
    rethrow(exception)
  end
  return true
end


"""
    generate(rng :: Random.AbstractRNG, T :: DataType)

Returns a single pseudorandomly chosen specimen corresponding to data type `T` for the `@quickcheck` macro.
`RandomPropertyTest` defines this function for some builtin types, for example `Int` and `Float32`.

To define a generator for your own custom type, `import RandomizedPropertyTest.generate` and specialize it for that type.

See also `specialcases`, `@quickcheck`.

Example
-------

Specialize `generate` to generate double-precision floats in the interval [0, π):

```jldoctest
julia> import Random

julia> struct MyRange; end

julia> RandomizedPropertyTest.generate(rng :: Random.AbstractRNG, _ :: Type{MyRange}) = rand(rng, Float64) * π;
```

This is just an example; in practice, consider using `Range{Float64, 0, π}` instead.
"""
function generate(rng :: AbstractRNG, types :: NTuple{N, DataType}) where {N}
  return (generate(rng, T) for T in types)
end


# Special cases for small numbers of variables increases performance by (15%, 30%, 40%, 40%) for (one, two, three, four) variables, respectively.
@inline function generate(rng :: AbstractRNG, types :: NTuple{1, DataType})
  return (generate(rng, types[1]),)
end
@inline function generate(rng :: AbstractRNG, types :: NTuple{2, DataType})
  return (generate(rng, types[1]), generate(rng, types[2]))
end
@inline function generate(rng :: AbstractRNG, types :: NTuple{3, DataType})
  return (generate(rng, types[1]), generate(rng, types[2]), generate(rng, types[3]))
end
@inline function generate(rng :: AbstractRNG, types :: NTuple{4, DataType})
  return (generate(rng, types[1]), generate(rng, types[2]), generate(rng, types[3]), generate(rng, types[4]))
end


function generate(rng :: AbstractRNG, _ :: Type{T}) where {T}
  rand(rng, T)
end


function generate(rng :: AbstractRNG, _ :: Type{Array{T,N}}) :: Array{T,N} where {T,N}
  shape = Int.(round.(1 .+ 3 .* randexp(rng, N))) # empty array is a special case
  return rand(rng, T, shape...)
end


for (TI, TF) in Dict(Int16 => Float16, Int32 => Float32, Int64 => Float64)
  @eval begin
    function generate(rng :: AbstractRNG, _ :: Type{$TF})
      x = $TF(NaN)
      while !isfinite(x)
        x = reinterpret($TF, rand(rng, $TI)) # generate a random int and pretend it is a float.
        # This gives an extremely broad distribution of floats.
        # Around 1% of the floats will have an absolute value between 1e-3 and 1e3.
      end
      return x
    end
  end
end


function generate(rng :: AbstractRNG, _ :: Type{Complex{T}}) where {T<:AbstractFloat}
  return complex(generate(rng, T), generate(rng, T))
end


"""
    specialcases(T :: DataType)

Returns a one-dimensional Array of values corresponding to `T` for the `@quickcheck` macro.
`RandomPropertyTest` overloads this function for some builtin types, for example `Int` and `Float64`.

To define special cases for your own custom data type, `import RandomizedPropertyTest.specialcases` and specialize it for that type.

See also `generate()`, `@quickcheck`.

Examples
--------

View special cases for the builtin type `Bool`:
```jldoctest
julia> RandomizedPropertyTest.specialcases(Bool)
2-element Array{Bool,1}:
  true
 false
```

Define special cases for a custom type:
```
julia> struct MyFloat; end

julia> RandomizedPropertyTest.specialcases(_ :: Type{MyFloat}) = Float32[0.0, Inf, -Inf, eps(0.5), π];
```
"""
function specialcases()
  return []
end


function specialcases(T :: DataType) :: Array{T,1}
  return []
end


function specialcases(types :: NTuple{N,DataType}) where {N}
  return Base.product((specialcases(T) for T in types)...)
end


function specialcases(_ :: Type{Array{T,N}}) :: Array{Array{T,N},1} where {T,N}
  d0 = [Array{T,N}(undef, repeat([0], N)...)]
  d1 = [reshape([x], repeat([1], N)...) for x in specialcases(T)]
  if N ≥ 3
    # For N ≥ 3, this uses huge amounts of memory, so we don't do it.
    d2_ = collect(Base.Iterators.product(repeat([specialcases(T)], 2^N)...))
    d2 = [Array{T,N}(reshape([d2_[i]...], repeat([2], N)...)) for i in 1:length(d2_)]
  else
    d2 = Array{Array{T,N},1}(undef, 0)
  end
  return cat(d0, d1, d2, dims=1)
end


function specialcases(_ :: Type{T}) :: Array{T,1} where {T<:AbstractFloat}
  return [
    T(0.0),
    T(1.0),
    T(-1.0),
    T(-0.5),
    T(1)/T(3),
    floatmax(T),
    floatmin(T),
    maxintfloat(T),
    -one(T) / maxintfloat(T),
    T(NaN),
    T(Inf),
    T(-Inf),
  ]
end


function specialcases(_ :: Type{Complex{T}}) :: Array{Complex{T},1} where {T <: AbstractFloat}
  return [complex(r, i) for r in specialcases(T) for i in specialcases(T)]
end


function specialcases(_ :: Type{T}) :: Array{T,1} where {T <: Signed}
  smin = one(T) << (8 * sizeof(T) - 1)
  smax = smin - one(T)
  return [
    T(0),
    T(1),
    T(-1),
    T(2),
    T(-2),
    smax,
    smin
  ]
end


function specialcases(_ :: Type{T}) :: Array{T} where {T <: Integer}
  return [
    T(0),
    T(1),
    T(2),
    ~T(0),
  ]
end


function specialcases(_ :: Type{Bool}) :: Array{Bool,1}
  return [
    true,
    false,
  ]
end


#=
   special datatypes
=#


"""
    Range{T,a,b}

Represents a range of variables of type `T`, with both endpoints `a` and `b` included.
`a` should be smaller than or eqaul to `b`.
Both `a` and `b` should be finite and non-NaN.

The type is used to generate variables of type `T` in the interval [`a`, `b`] for the `@quickcheck` macro:
```
julia> @quickcheck (typeof(x) == Int && 23 ≤ x ≤ 42) (x :: Range{Int, 23, 42})
true
```
"""
# Note: Having a and b (the range endpoints) as type parameters is a bit unfortunate.
# It means that for ranges with the same type T but different endpoints, all relevant functions have to be recompiled.
# However, it is required because of generate(::NTuple{N, DataType}).
# Anyway, it is only for tests, so it should not be too much of a problem.
struct Range{T,a,b} end

export Range


function generate(rng :: AbstractRNG, _ :: Type{Range{T,a,b}}) :: T where {T<:AbstractFloat,a,b}
  a ≤ b && isfinite(a) && isfinite(b) || error("a needs to be ≤ b and both need to be finite")
  a + rand(rng, T) * (b - a) # The endpoints are included via specialcases()
end


function generate(rng :: AbstractRNG, _ :: Type{Range{T,a,b}}) :: T where {T<:Integer,a,b}
  a ≤ b || error("a needs to be ≤ b")
  rand(rng, a:b)
end


function specialcases(_ :: Type{Range{T,a,b}}) :: Array{T,1} where {T<:AbstractFloat,a,b}
  return [
    T(a),
    T(a) + (T(b)/2 - T(a)/2),
    T(b),
  ]
end


function specialcases(_ :: Type{Range{T,a,b}}) :: Array{T,1} where {T<:Integer,a,b}
  return [
    T(a),
    div(T(a)+T(b), 2),
    T(b),
  ]
end


"""
    Disk{T,z₀,r}

Represents a Disk of radius `r and center `z₀` in the set `T` (boundary excluded).
`r` should be nonnegative.
Both `z` and `r` should be finite and non-NaN.

The type is used to generate variables `x` of type `T` such that (abs(x-z) < r) for the `@quickcheck` macro:
```
julia> @quickcheck (typeof(x) == ComplexF16 && abs(x-2im) < 3) (x :: Disk{Complex{Float16}, 2im, 3})
true
```
"""
struct Disk{T,z₀,r} end

export Disk


function generate(rng :: AbstractRNG, _ :: Type{Disk{Complex{T},z₀,r}}) :: Complex{T} where {T<:AbstractFloat,z₀,r}
  r ≥ 0 || error("r needs to be ≥ 0")
  isfinite(z₀) || error("z₀ needs to be finite")
  z = Complex{T}(Inf, Inf)
  while !(abs(z - z₀) < r)
    z = r * complex(2rand(rng, T)-1, 2rand(rng, T)-1) + z₀
  end
  return z
end


function specialcases(_ :: Type{Disk{Complex{T},z₀,r}}) :: Array{Complex{T},1} where {T<:AbstractFloat,z₀,r}
  return [
    Complex{T}(z₀)
  ]
end


end
