module Hyperspecialize



using InteractiveUtils
using Base.Iterators



export @concretize, @concretization, @widen, @replicable



postwalk(f, x) = f(x)
postwalk(f, x::Expr) = f(Expr(x.head, map(arg->postwalk(f, arg), x.args)...))



macro isdefined(var)
 quote
   try
     local _ = $(esc(var))
     true
   catch err
     isa(err, UndefVarError) ? false : rethrow(err)
   end
 end
end



"""
    concretesubtypes(t)

Return an `Array` containing all concrete subtypes of `t` at load time.

# Examples
```julia-repl
julia> Hyperspecialize.concretesubtypes(Real)
16-element Array{Any,1}:
 BigFloat
 Float16
 Float32
 Float64
 Bool
 BigInt
 Int128
 Int16
 Int32
 Int64
 Int8
 UInt128
 UInt16
 UInt32
 UInt64
 UInt8
```
"""
function concretesubtypes(t)
  if isconcretetype(t)
    return [t]
  else
    return vcat([concretesubtypes(s) for s in subtypes(t)]...)
  end
end



"""
    allsubtypes(t)

Return an `Array` containing all subtypes of `t` at load time.

# Examples
```julia-repl
julia> Hyperspecialize.allsubtypes(Real)
24-element Array{Type,1}:
 Real
 AbstractFloat
 BigFloat
 Float16
 Float32
 Float64
 AbstractIrrational
 Irrational
 Integer
 Bool
 Signed
 BigInt
 Int128
 Int16
 Int32
 Int64
 Int8
 Unsigned
 UInt128
 UInt16
 UInt32
 UInt64
 UInt8
 Rational
```
"""
function allsubtypes(t)
  return vcat([t], [allsubtypes(s) for s in subtypes(t)]...)
end



function parse_element(base_mod, T)
  if T isa Expr && T.head == :. && length(T.args) == 2
    (M, K) = T.args
  else
    M = base_mod
    K = QuoteNode(T)
  end
  return (M, K)
end



struct Replicable
  E::Any
  defined::Set{Tuple{Vararg{Type}}}
  type_tags::Vector{Tuple{Module, Symbol}}
end

struct Concretization
  base::Set{Type}
  contextual::Dict{Tuple{Module, Int}, Set{Type}}
  replicable_tags::Vector{Tuple{Module, Int}}
  Concretization(types::Set{Type}) = new(types, Dict{Tuple{Module, Int}, Set{Type}}(), Vector{Tuple{Module, Int}}())
end

struct State
  replicables::Vector{Replicable}
  concretizations::Dict{Symbol, Concretization}
  State() = new(Vector{Replicable}(), Dict{Symbol, Concretization}())
end



function _concretize(base_mod::Module, target_mod::Module, key::Symbol, types::Type)
  return _concretize(base_mod, target_mod, key, [types])
end

function _concretize(base_mod::Module, target_mod::Module, key::Symbol, types)
  return _concretize(base_mod, target_mod, key, Set{Type}(types))
end

function _concretize(base_mod::Module, target_mod::Module, key::Symbol, types::Set{Type})
  if base_mod == target_mod
    if !isdefined(base_mod, :__hyperspecialize__)
      Core.eval(base_mod, quote
        const global __hyperspecialize__ = Hyperspecialize.State()
      end)
    end
    if haskey(target_mod.__hyperspecialize__.concretizations, key)
      error("cannot reconcretize \"$key\" in module \"$target_mod\"")
    else
      target_mod.__hyperspecialize__.concretizations[key] = Concretization(types)
    end
  else
    error("cannot concretize \"$key\" in module \"$target_mod\" from module \"$base_mod\"")
  end
  return Set{Type}(target_mod.__hyperspecialize__.concretizations[key].base)
end

"""
    @concretize(typetag, types)

Define the set of types corresponding to a type tag as `types`, where `types`
is either a single type or any collection that may be passed to a set
constructor.  A type tag is a module-qualified symbol `mod.:Key` where mod
specifies a module and `:Key` is a symbol.  If just the `:Key` is given, then
the module is assumed to be the module in which the macro was expanded.

Note that you may not concretize a type in another module.

# Examples
```julia-repl
julia> @concretize Main.BestInts [Int32, Int64]
Set(Type[Int32, Int64])

julia> @concretize BestFloats Float64
Set(Type[Float64])

julia> @concretize BestStrings (String,)
Set(Type[String])

julia> @concretization BestInts
Set(Type[Int32, Int64])
```
"""
macro concretize(K, T)
  (M, K) = parse_element(__module__, K)
  return :(_concretize($(esc(__module__)), $(esc(M)), $(K), $(esc(T))))
end



function _concretize(base_mod::Module, target_mod::Module, key::Symbol)
  if _concretization(base_mod, target_mod, key) == nothing
    if isdefined(target_mod, key)
      if Core.eval(target_mod, key) isa Type
        _concretize(base_mod, target_mod, key, concretesubtypes(Core.eval(target_mod, key)))
      else
        error("cannot create default concretization from type tag $target_mod.$key: not a type")
      end
    else
      error("cannot create default concretization from type tag $target_mod.$key: not defined")
    end
  end
  return _concretization(base_mod, target_mod, key)
end

"""
    @concretize(typetag)

If no concretization exists, define the set of types corresponding to `typetag`
as the concrete subtypes of whatever type shares the name of `Key` at load
time.  `typetag` is a type tag, or a module-qualified symbol `mod.:Key` where
mod specifies a module and `:Key` is a symbol.  If just the `:Key` is given,
then the module is assumed to be the module in which the macro was expanded.

Note that you may not concretize a type tag in another module.

# Examples
```julia-repl
julia> @concretization(Main.Real)
nothing

julia> @concretize(Main.Real)
Set(Type[BigInt, Bool, UInt32, Float64, Float32, Int64, Int128, Float16, UInt128, UInt8, UInt16, BigFloat, Int8, UInt64, Int16, Int32])

julia> @concretize BestInts [Int32, Int64]
Set(Type[Int32, Int64])

julia> @concretization BestInts
Set(Type[Int32, Int64])

julia> @concretize NotDefinedHere
ERROR: cannot create default concretization from type tag Main.NotDefinedHere: not defined.
```
"""
macro concretize(K)
  (M, K) = parse_element(__module__, K)
  return :(_concretize($(esc(__module__)), $(esc(M)), $(K)))
end



function _concretization(base_mod::Module, target_mod::Module, key::Symbol)
  if !isdefined(target_mod, :__hyperspecialize__) || !haskey(target_mod.__hyperspecialize__.concretizations, key)
    return nothing
  end
  return Set{Type}(target_mod.__hyperspecialize__.concretizations[key].base)
end

"""
    @concretization(typetag)

Return the set of types corresponding to a type tag.  A type tag is a
module-qualified symbol `mod.:Key` where mod specifies a module and `:Key` is a
symbol.  If just the `:Key` is given, then the module is assumed to be the
module in which the macro was expanded.  If no concretization exists, return
nothing.

A concretization can be set and modified with `@concretize` and `@widen`

# Examples
```julia-repl
julia> @concretization(BestInts)
nothing

julia> @concretize BestInts [Int32, Int64]
Set(Type[Int32, Int64])

julia> @concretization BestInts
Set(Type[Int32, Int64])
```
"""
macro concretization(K)
  (M, K) = parse_element(__module__, K)
  return :(_concretization($(esc(__module__)), $(esc(M)), $(K)))
end



function _widen(base_mod::Module, target_mod::Module, key::Symbol, types::Type)
  return _widen(base_mod, target_mod, key, [types])
end

function _widen(base_mod::Module, target_mod::Module, key::Symbol, types)
  return _widen(base_mod, target_mod, key, Set{Type}(types))
end

function _widen(base_mod::Module, target_mod::Module, key::Symbol, types::Set{Type})
  _concretize(base_mod, target_mod, key)
  union!(target_mod.__hyperspecialize__.concretizations[key].base, types)
  map(((target_mod, num),) -> _define(base_mod, target_mod, target_mod.__hyperspecialize__.replicables[num]), target_mod.__hyperspecialize__.concretizations[key].replicable_tags)
  return Set{Type}(target_mod.__hyperspecialize__.concretizations[key].base)
end

"""
    @widen(typetag, types)

Expand the set of types corresponding to a type tag to include `types`, where
`types` is either a single type or any collection that may be passed to a set
constructor.  A type tag is a module-qualified symbol `mod.:Key` where mod
specifies a module and `:Key` is a symbol.  If just the `:Key` is given, then
the module is assumed to be the module in which the macro was expanded.  If no
concretization exists, create a default concretization consisting of the
conrete subtypes of whatever type shares the name of `Key` at load time.

If `@widen` is called for a type tag which has been referenced by a
`@replicable` code block, then that code block will be replicated even more to
reflect the new concretization.

# Examples
```julia-repl
julia> @concretize BestInts [Int32, Int64]
Set(Type[Int32, Int64])

julia> @replicable println(@hyperspecialize(BestInts))
Int32
Int64

julia> @widen BestInts (Bool, Int32, UInt128)
Bool
UInt128
Set(Type[Bool, UInt128, Int32, Int64])

julia> @concretization BestInts
Set(Type[Bool, Int8, Int32, Int64, UInt128])
```
"""
macro widen(K, T)
  (M, K) = parse_element(__module__, K)
  return :(_widen($(esc(__module__)), $(esc(M)), $(K), $(esc(T))))
end



_is_hyperspecialize(X) = false
function _is_hyperspecialize(X::Expr)
  return X.head == :macrocall &&
    length(X.args) == 3 &&
    X.args[1] == Symbol("@hyperspecialize")
end

function _get_hyperspecialize(X)
  @assert _is_hyperspecialize(X)
  return X.args[3]
end

function _define(base_mod::Module, target_mod::Module, replicable::Replicable)
  for types in product(map(type_tag -> _concretization(base_mod, type_tag...), replicable.type_tags)...)
    if !(types in replicable.defined)
      Core.eval(target_mod, postwalk(X -> begin
        if _is_hyperspecialize(X)
          types[_get_hyperspecialize(X)]
        else
          X
        end
      end, replicable.E))
      push!(replicable.defined, types)
    end
  end
end

function _replicable(base_mod::Module, E, type_tags::Tuple{Module, Symbol}...)
  if !isdefined(base_mod, :__hyperspecialize__)
    Core.eval(base_mod, quote
      const global __hyperspecialize__ = Hyperspecialize.State()
    end)
  end
  replicable = Replicable(E, Set{Any}(), [type_tags...])
  push!(base_mod.__hyperspecialize__.replicables, replicable)
  num = length(base_mod.__hyperspecialize__.replicables)
  for (target_mod, key) in type_tags
    _concretize(base_mod, target_mod, key)
    push!(target_mod.__hyperspecialize__.concretizations[key].replicable_tags, (base_mod, num))
  end
  _define(base_mod, base_mod, replicable)
end

"""
    @replicable block

Replicate the code in `block` where each type tag referred to by
`@hyperspecialize(typetag)` is replaced by an element in the concretization of
`typetag`.  `block` is replicated at global scope in the module where
`@replicable` was expanded once for each combination of types in the
concretization of each `typetag`.  A type tag is a module-qualified symbol
`mod.:Key` where mod specifies a module and `:Key` is a symbol.  If just the
`:Key` is given, then the module is assumed to be the module in which the macro
was expanded.  If no concretization exists for a type tag, create a default
concretization consisting of the conrete subtypes of whatever type shares the
name of `Key` at load time.

If `@widen` is called for a type tag which has been referenced by a
`@replicable` code block, then that code block will be replicated even more to
reflect the new concretization.

# Examples
```julia-repl
julia> @concretize BestInts [Int32, Int64]
Set(Type[Int32, Int64])

julia> @replicable println(@hyperspecialize(BestInts), @hyperspecialize(BestInts))
Int32Int32
Int32Int64
Int64Int32
Int64Int64

julia> @widen BestInts (Bool,)
BoolBool
BoolInt32
BoolInt64
Int32Bool
Int64Bool
Set(Type[Bool, Int32, Int64])
```
"""
macro replicable(E)
  elements = []
  count = 0
  E = postwalk(X -> begin
    if _is_hyperspecialize(X)
      (M, K) = parse_element(__module__, _get_hyperspecialize(X))
      push!(elements, :(($(esc(M)), $(K))))
      count += 1
      :(@hyperspecialize($count))
    else
      X
    end
  end, E)
  return :(_replicable($(esc(__module__)), $(QuoteNode(E)), $(elements...)))
end

end # module
