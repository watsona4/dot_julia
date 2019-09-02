/#
 # This file is part of OpenModelica.
 #
 # Copyright (c) 1998-Current year, Open Source Modelica Consortium (OSMC),
 # c/o Linköpings universitet, Department of Computer and Information Science,
 # SE-58183 Linköping, Sweden.
 #
 # All rights reserved.
 #
 # THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 LICENSE OR
 # THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
 # ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 # RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3,
 # ACCORDING TO RECIPIENTS CHOICE.
 #'
 # The OpenModelica software and the Open Source Modelica
 # Consortium (OSMC) Public License (OSMC-PL) are obtained
 # from OSMC, either from the above address,
 # from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 # http://www.openmodelica.org, and in the OpenModelica distribution.
 # GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 #
 # This program is distributed WITHOUT ANY WARRANTY; without
 # even the implied warranty of  MERCHANTABILITY or FITNESS
 # FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 # IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 #
 # See the full OSMC Public License conditions for more details.
 #
 #/

"""
  This module provides an immutable list compatible with
  the MetaModelica list datatype. It is immutable and supports common operations
  associated with immutable single linked lists such as map and reduce.
"""
module ListDef


#=!!! Observe we only EVER create Nil{Any} !!!=#
struct Nil{T} end

struct Cons{T}
  head::T
  tail::Union{Nil, Cons{T}}
end

const List{T} = Union{Nil{T}, Cons{T}, Nil}
List() = Nil{Any}()
Nil() = List()

#=
  These promotion rules might seem a bit odd. Still it is the most efficient way I found of casting immutable lists
  If someone see a better alternative to this approach please fix me :). Basically I create a new list in O(N) * C time
  with the type we cast to. Also, do not create new conversion strategies without measuring performance as they will call themselves
  recursivly
=#

""" For converting lists with more then one element"""
Base.convert(::Type{List{S}}, x::Cons{T}) where {S, T <: S} = let
  List(S, x)
end

""" For converting lists of lists """
Base.convert(::Type{T}, x::Cons) where {T <: List} = let
  x isa T ? x : List(eltype(T), x)
end

#= Identiy cases =#
Base.convert(::Type{List{T}}, x::Cons{T}) where {T} = x
Base.convert(::Type{Cons{T}}, x::Cons{T}) where {T} = x
Base.convert(::Type{Nil}, x::Nil) where {T} = nil

Base.promote_rule(a::Type{Cons{T}}, b::Type{Cons{S}}) where {T,S} = let
  el_same(promote_type(T,S), a, b)
end

#= Definition of eltype =#
Base.eltype(::Type{List{T}}) where {T} = let
  T
end

Base.eltype(::List{T}) where {T} = let
  T
end

Base.eltype(::Type{Cons{T}}) where {T} = let
  T
end

Base.eltype(::Type{Nil}) where {T} = let
  Nil
end

Base.eltype(::Nil) where {T} = let
  Any
end

""" O(n) """
function listReverse(inLst::List{T})::List{T} where {T}
  local outLst::List = nil
  if isa(inLst, Nil)
    return nil
  end
  while true
    if isa(inLst, Nil)
      break
    end
    outLst = Cons{T}(inLst.head, outLst)
    inLst = inLst.tail
  end
  outLst
end


""" For \"Efficient\" casting... O(N) * C" """
List(T::Type #= Hack.. =#, args) = let
  if args isa Nil
    return nil
  end
  local lst1::Cons{T} = Cons{T}(convert(T, args.head) ,nil)
  if args.tail isa Nil
    return lst1
  end
  for i in args.tail
    lst1 = Cons{T}(convert(T, i), lst1)
  end
  listReverse(lst1)
end

#= if the head element is nil the list is empty.=#
const nil = List()
list() = nil

#= Support for primitive constructs. Numbers. Integer bool e.t.c =#
function list(els::T...)::List{T} where {T <: Number}
  local lst::List{T} = nil
  for i in length(els):-1:1
    lst = Cons{T}(els[i], lst)
  end
  lst
end

#= Support hieractical constructs. Concrete elements =#
function list(a::A, b::B, els...) where {A, B}
  local S::Type = typejoin(A, B, eltype(els))
  @assert S != Any
  local lst::Cons{S} = Cons{S}(a, Cons{S}(b, nil))
  for i in length(els):-1:1
    lst = Cons{S}(els[i], lst)
  end
  lst
end

#= List of one element =#
function list(a::T) where {T}
  Cons{T}(a, nil)
end

#= List of two elements =#
function list(a::A, b::B) where {A, B}
  local S::Type = typejoin(A, B)
  @assert S != Any
  Cons{S}(a, Cons{S}(b, nil))
end

cons(v::T, ::Nil) where {T} = Cons{T}(v, nil)
cons(v::T, l::Cons{T}) where {T} = Cons{T}(v, l)
cons(v::A, l::Cons{B}) where {A,B} = let
  C = typejoin(A,B)
  @assert C != Any
  Cons{C}(convert(C,v),convert(Cons{C},l))
end

"""
_cons is a special cons function that returns a list of the common
abstract type instead of the type of the struct itself. Using this
may avoid future type conversions on the entire list to occur.
Use this in particular in generated code where you cannot use cons
responsibly.
"""
function _cons(head::A, tail::Cons{B}) where {A,B}
  C = typejoin(A,B)
  D = supertype(C)
  if isstructtype(C) && !isabstracttype(C) && isabstracttype(D)
    Cons{D}(convert(D,head),convert(List{D},tail))
  else
    Cons{C}(convert(C,head),convert(List{C},tail))
  end
end
_cons(head::T, tail::Nil) where {T} = Cons{T}(head, nil)

consExternalC(::Type{T}, v :: X, l :: List{T}) where {T, X <: T} = Cons{T}(v, l) # Added for the C interface to be happy

""" <| Right associative cons operator """
<|(v, lst::Nil)  = cons(v, nil)
<|(v, lst::Cons{T}) where{T} = cons(v, lst)
<|(v::S, lst::Cons{T}) where{T, S <: T} = cons(v, lst)

Base.length(l::Nil)::Int = 0

function Base.length(l::List)::Int
  local n::Int = 0
  for _ in l
    n += 1
  end
  n
end

Base.iterate(::Nil) = nothing
Base.iterate(x::Cons, y::Nil) = nothing
function Base.iterate(l::Cons, state::List = l)
    state.head, state.tail
end

"""
  For list comprehension. Unless we switch to mutable structs this is the way to go I think.
  Seems to be more efficient then what the omc currently does.
"""
list(F, C::Base.Generator) = let
  list(collect(Base.Generator(F, C))...)
end

""" Comprehension without a function(!) """
list(C::Base.Generator) = let
  #= Just apply the element to itself =#
  list(i->i, C)
end

""" Adds the ability for Julia to flatten MMlists """
list(X::Base.Iterators.Flatten) = let
  list([X...]...)
end

"""
  List Reductions
"""
list(X::Base.Generator{Base.Iterators.ProductIterator{Y}, Z}) where {Y,Z} = let
  x = collect(X)
  list(list(i...) for i in view.([x], 1:size(x, 1), :))
end

"""
Generates the transformation:
 @do_threaded_for expr with (iter_names) iterators =>
  \$expr for \$iterator_names in list(zip(\$iters...)...)
"""
function make_threaded_for(expr, iter_names, ranges)
  iterExpr::Expr = Expr(:tuple, iter_names.args...)
  rangeExpr::Expr = ranges = [ranges...][1]
  rangeExprArgs = rangeExpr.args
  :($expr for $iterExpr in [ zip($(rangeExprArgs...))... ]) |> esc
end

macro do_threaded_for(expr::Expr, iter_names::Expr, ranges...)
  make_threaded_for(expr, iter_names, ranges)
end

""" Sorts the list by first converting it into an array """
Base.sort(lst::List) = let
  list(sort(collect(lst))...)
end

export List, list, cons, <|, nil, _cons
export @do_threaded_for, Cons, Nil, listReverse

end
