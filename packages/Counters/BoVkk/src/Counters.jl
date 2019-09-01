module Counters

export Counter, counter, clean!, incr!, mean, csv_print

import Base: show, length, getindex, sum, keys, (+), (==), hash
import Base:  setindex!, collect
import Base: iterate
#import Base: start, done, next, iterate

using SparseArrays, Statistics
#import SparseArrays: nnz
#import Statistics: mean

"""
A `Counter` is a device for keeping a count of how often we observe
various objects. It is created by giving a type such as
`c=Counter{String}()`.

Counts are retrieved with square brackets like a dictionary: `c["hello"]`.
It is safe to retrieve the count of an object never encountered, e.g.,
`c["goodbye"]`; in this case `0` is returned.

Counts may be assigned with `c[key]=amount`, but the more likely use
case is using `c[key]+=1` to count each time `key` is encountered.
"""
struct Counter{T<:Any} <: AbstractDict{T,Int}
  data::Dict{T,Int}
  function Counter{T}() where T
    d = Dict{T,Int}()
    C = new(d)
  end
end

Counter() = Counter{Any}()

# These items enable this to satisfy the Associative properties
#
# start(c::Counter) = start(c.data)
# done(c::Counter,s) = done(c.data,s)
# next(c::Counter,s) = next(c.data,s)

iterate(C::Counter{T}) where T = iterate(keys(C.data))
iterate(C::Counter{T}, s::Int) where T = iterate(keys(C.data), s)



"""
`length(c::Counter)` gives the number of entries monitored
by the Counter. Conceivably, some may have value `0`.

See also: `nnz`.
"""
length(c::Counter) = length(c.data)

function show(io::IO, c::Counter{T}) where T
  n = length(c.data)
  word = ifelse(n==1, "entry", "entries")
  msg = "with $n $word"
  print(io,"Counter{$T} $msg")
end

show(c::Counter{T}) where T = show(stdout,c)

import Base.Multimedia.display

function display(c::Counter{T}) where T
  println("Counter{$T} with these nonzero values:")
  klist = collect(keys(c))
  try
    sort!(klist)
  catch
    1+1 # no action required if fail to sort
  end

  for k in klist
    if c[k] != 0
      println("$k ==> $(c.data[k])")
    end
  end
end



function getindex(c::Counter{T}, x::T) where T
  return get(c.data,x,0)
end

"""
`keys(c::Counter)` returns an interator for the things counted by `c`.
"""
keys(c::Counter) = keys(c.data)


"""
`sum(c::Counter)` gives the total of the counts for all things
in `c`.
"""
sum(c::Counter) = sum(values(c.data))

"""
`nnz(c::Counter)` gives the number of keys in
the `Counter` with nonzero value.

See also: `length`.
"""
function SparseArrays.nnz(c::Counter)
  amt::Int = 0
  for k in keys(c)
    if c.data[k] != 0
      amt += 1
    end
  end
  return amt
end

setindex!(c::Counter{T}, val::Int, k::T) where T = c.data[k] = val>0 ? val : 0

function ==(c::Counter{T}, d::Counter{T}) where T
  for k in keys(c)
    if c[k] != d[k]
      return false
    end
  end

  for k in keys(d)
    if c[k] != d[k]
      return false
    end
  end

  return true
end

isequal(c::Counter{T},d::Counter{T}) where T = c==d

"""
`clean!(c)` removes all keys from `c` whose value is `0`.
Generally, it's not necessary to invoke this unless one
suspects that `c` contains *a lot* of keys associated with
a zero value.
"""
function clean!(c::Counter{T}) where T
  for k in keys(c)
    if c[k] == 0
      delete!(c.data,k)
    end
  end
  nothing
end

"""
`incr!(c,x)` increments the count for `x` by 1. This is equivalent to
`c[x]+=1`.

`incr!(c,items)` is more useful. Here `items` is an iterable collection
of keys and we increment the count for each element in `items`.

`incr!(c,d)` where `c` and `d` are counters will increment `c` by
the amounts held in `d`.
"""
incr!(c::Counter{T}, x::T) where T = c[x] += 1

function incr!(c::Counter, items)
  for x in items
    c[x] += 1
  end
end

function incr!(c::Counter{T},d::Counter{T}) where T
  for k in keys(d)
    c[k] += d[k]
  end
end


"""
If `c` and `d` are `Counter`s, then `c+d` creates a new `Counter`
in which the count associated with an object `x` is `c[x]+d[x]`.
"""
function (+)(c::Counter{T}, d::Counter{T}) where T
  result = deepcopy(c)
  incr!(result,d)
  return result
end

"""
`collect(C)` for a `Counter` returns an array containing the elements of `C`
each repeated according to its multiplicty.
"""
function collect(c::Counter{T}) where T
  result = Vector{T}(undef,sum(c))
  idx = 0
  for k in keys(c)
    m = c[k]
    for j=1:m
      idx += 1
      result[idx] = k
    end
  end
  return result
end



"""
`mean(C::Counter)` computes the weighted average of the objects in `C`.
Of course, the counted objects must be a `Number`; their multiplicity
(weight) in the average is determined by their `C`-value.
"""
function mean(C::Counter{T}) where T<:Number
  total = zero(T)
  for k in keys(C)
    total += k * C[k]
  end
  return total / sum(C)
end

"""
`csv_print(C::Counter)` prints out `C` in a manner suitable for import into
a spreadsheet.
"""
function csv_print(C::Counter)
  klist = collect(keys(C))
  try
    sort!(klist)
  catch
  end
  for k in klist
    println("$k, $(C[k])")
  end
  nothing
end

"""
`counter(list)` creates a `Counter` whose elements are the
members of `list` with the appropriate multiplicities.
This may also be used if `list` is a `Set` or an `IntSet`
(in which case multiplicities will all be 1).
"""
function counter(list::AbstractArray)
  T = eltype(list)
  C = Counter{T}()
  for x in list
    incr!(C,x)
  end
  return C
end

counter(S::Base.AbstractSet) = counter(collect(S))


"""
Performing `hash` on a `Counter` will first apply `clean!` to the
`Counter` in order that equal `Counter` objects hash the same.
"""
function hash(C::Counter, h::UInt64 = UInt64(0))
    clean!(C)
    return hash(C.data,h)
end

end # module
