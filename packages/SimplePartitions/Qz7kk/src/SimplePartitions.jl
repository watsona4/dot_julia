module SimplePartitions
using DataStructures, Permutations

import Base.show, Base.==, Base.join, Base.+, Base.*, Base.in
import Base.<, Base.<=, Base.>, Base.>=

import AbstractLattices: ∧, ∨

export Partition, set_element_type, num_elements, num_parts, parts
export ground_set, merge_parts!, PartitionBuilder
export in_same_part, find_part, meet, refines, ∧, ∨

"""
`set_element_type(A)` gives the element type of a set `A`.
"""
function set_element_type(A::Set{T}) where T
  return T
end
set_element_type(B::BitSet) = Int


"""
A `Partition` is a set of nonempty, pairwise disjoint sets.
A new `Partition` is created by specifying the ground set `A`
and calling `Partition(A)`. The set `A` may be either a `Set{T}`
for some type `T` or an `BitSet`.

The parameter `A` may also be a list (one-dimensional array).

In addition, `Partition(n)` for a nonnegative integer `n` creates
a partition of the set {1,2,...,n}.

The datatype `Partition` is, essentially, a wrapper around the
`DataStructures.DisjointSets` type.
"""
mutable struct Partition{T}
  elements::Set{T}
  parts::DisjointSets{T}
  SOS::Set{Set{T}}  # set of sets representation

  function Partition{T}() where T
    A = Set{T}()
    return Partition(A)
  end

  function Partition{T}(A::Set{T}) where T
    elts = deepcopy(A)
    pts  = DisjointSets{T}(elts)
    sos = Set{Set{T}}()
    for a in A
      S = Set{T}([a])
      push!(sos,S)
    end
    new(elts,pts,sos)
  end
end # end type definition


function Partition(A::Set)
  T = set_element_type(A)
  return Partition{T}(A)
end
Partition(B::BitSet) = Partition{Int}(Set{Int}(B))

# Also construct from a vector
Partition(list::Vector{T}) where T = Partition(Set(list))
Partition(n::Int) = Partition(Set(1:n))
Partition() = Partition{Any}()


"""
`Partition(p::Permutation)` constructs a new partition in which the
parts are the cycles of the permutation `p`.
"""
function Partition(p::Permutation)
  n = length(p)
  P = Partition(n)
  clist = cycles(p)
  for C in clist
    merge_parts!(P,C)
  end
  return P
end

"""
`Partition(d::Dict)` constructs a new partition
whose elements are the keys of `d`. Two elements
`a` and `b` are in the same part of the partition
iff `d[a]==d[b]`.
"""
function Partition(d::Dict)
  K = collect(keys(d))
  P = Partition(K)
  n = length(K)
  for i=1:n-1
    a = K[i]
    for j=i+1:n
      b = K[j]
      if d[a]==d[b]
        merge_parts!(P,a,b)
      end
    end
  end
  return P
end



"""
`kill_sos!(P)` wipes out the set-of-sets cache. Only used
internally.
"""
kill_sos!(P::Partition{T}) where T = P.SOS = Set{Set{T}}()

# Construct a Partition from a set of sets
"""
`PartitionBuilder(A,check=true)` takes a set of nonempty, pairwise disjoint
sets and creates the corresponding partition. It is the inverse operation
to `parts(P)`. The optional parameter `check` causes sanity checks to be return
on the input set of sets (throwing errors if it is invalid).
"""
function PartitionBuilder(A::Set{Set{T}}, check::Bool=true) where T
  parts_list = collect(A)
  np = length(parts_list)
  parts_sum = 0

  if check
    for p in parts_list
      np = length(p)
      @assert np>0 "The sets in the input must be nonempty."
      parts_sum += np
    end
  end

  ground = Set{T}()
  for p in parts_list
    for a in p
      push!(ground, a)
    end
  end

  if check
    @assert length(ground) == parts_sum "The sets in the input must be pairwise disjoint."
  end

  P = Partition(ground)

  for p in parts_list
    plist = collect(p)
    np = length(plist)
    for k=1:np-1
      merge_parts!(P,plist[k], plist[k+1])
    end
  end
  kill_sos!(P)
  return P
end

# Equality check
==(P::Partition, Q::Partition) = parts(P)==parts(Q)

# Hashing
import Base.hash
function hash(P::Partition{T},h::UInt64=UInt64(0)) where T
  if length(P.SOS)==0 && num_parts(P)>0
    build_sos!(P)
  end
  hash(P.SOS,h)
end

# Display
function show(io::IO, P::Partition)
  print(io, parts(P))
end

"""
`in(a,P)` checks if `a` is in the ground set of `P` and
`in(A,P)` checks if `A` is a part of `P`.
"""
function in(a::T,P::Partition{T}) where T
  return in(a,P.elements)
end

function in(A::Set{T}, P::Partition{T}) where T
  return in(A, parts(P))
end


"""
`merge_parts!(P,a,b)` updates `P` by merging the parts
that contain elements `a` and `b`.
"""
function merge_parts!(P::Partition{T},a::T,b::T) where T
  @assert in(a,P)&&in(b,P) "One or both of these elements is not in the partition."
  union!(P.parts,a,b)
  kill_sos!(P)
  nothing
end

"""
`merge_parts!(P,elts)` merges all the elements in `elts` into a
part. Thus `merge_parts!(P,[a,b])` is equivalent to
`merge_parts!(P,a,b)`.
"""
function merge_parts!(P::Partition{T}, elts::Vector{T}) where T
  ne = length(elts)
  for k=1:ne-1
    merge_parts!(P,elts[k],elts[k+1])
  end
end


"""
`num_parts(P)` gives the number of parts in the partition `P`.
"""
num_parts(P::Partition) = num_groups(P.parts)

"""
`num_elements(P)` gives the number of elements in the ground
set of the partition `P`. This equals the sum of the sizes of the
parts.
"""
num_elements(P::Partition) = length(P.elements)

"""
`elements(P)` returns (a copy of) the ground set of the
partition `P`.
"""
ground_set(P::Partition) = deepcopy(P.elements)


import Base.collect

"""
`collect(P::Partition)` returns a list of the parts of the
partition `P`.
"""
collect(P::Partition) = collect(parts(P))


"""
`parts(P)` returns a set containing the parts of the partition `P`.
That is, we return a set of sets.
"""
function parts(P::Partition{T}) where T
  if length(P.SOS)==0 && num_parts(P)>0
    build_sos!(P)
  end
  return deepcopy(P.SOS)
end

# using internally by parts(P); not exposed
function build_sos!(P::Partition{T}) where T
  n = num_parts(P)
  GS = P.elements

  # Find the indices of the roots of the parts
  root_set = Set{T}()
  for item in GS
    r = find_root(P.parts,item)
    push!(root_set,r)
  end
  roots = collect(root_set)  # make it an array

  # Create a mapping from root numbers to [1:n]
  rootmap = Dict{T,Int}()
  for k=1:n
    rootmap[roots[k]] = k
  end

  # Create an array of sets to hold the parts
  plist = Array{Set{T}}(undef,n)
  for k=1:n
    plist[k] = Set{T}()  # make sure they're empty sets
  end

  # For each element in the ground set, look up its root
  # in order to place it in its appropriate set.
  for item in GS
    idx = rootmap[find_root(P.parts,item)]
    push!(plist[idx], item)
  end

  # now take those parts and pack them into a set
  S = Set{Set{T}}()
  for item in plist
    push!(S,item)
  end
  P.SOS = S
  nothing
end

"""
`in_same_part(P,a,b)` returns `true` if `a` and `b` are in the same part
of the partition `P`. An error is thrown if either is not in the ground
set of `P`.
"""
function in_same_part(P::Partition{T},a::T,b::T) where T
  @assert in(a,P)&&in(b,P) "One or both of these elements is not in the partition."
  return find_root(P.parts,a) == find_root(P.parts,b)
end

"""
`find_part(P,a)` returns the part of `P` that contains `a` (or throws an
error if `a` is not in the ground set).
"""
function find_part(P::Partition{T},a::T) where T
  @assert in(a,P) "$a is not in the ground set of this partition."
  r = find_root(P.parts,a)
  A = Set{T}()
  for x in P.elements
    if find_root(P.parts,x) == r
      push!(A,x)
    end
  end
  return A
end

"""
`join(P,Q)` computes the join of the two partitions. This may also
be invoked as `P+Q`.
"""
function join(P::Partition{T}, Q::Partition{T}) where T
  @assert P.elements==Q.elements "The ground sets of the two partitions must be the same."

  R = Partition(P.elements)
  PP = union(parts(P), parts(Q))

  for p in PP
    items = collect(p)
    n = length(items)
    for i=1:n-1
      merge_parts!(R,items[i],items[i+1])
    end
  end
  return R
end

"""
For partitions `P` and `Q`, `P+Q` is their join.
"""
(+)(P::Partition, Q::Partition) = join(P,Q)

"""
For partitions `P` and `Q`, `P∨Q` is their join.
"""
(∨)(P::Partition, Q::Partition) = join(P,Q)


"""
For a partition `P` and element `x`, `P+x` builds a new partition
that adds `x` as a singleton element.
"""
function (+)(P::Partition{T}, x::T) where T
  @assert !(in(x,P.elements)) "This element is already in the ground set of this partition."
  sets = parts(P)
  singlet = Set{T}(x)
  push!(sets,singlet)
  return PartitionBuilder(sets)
end

"""
For a partition `P` and a set `A`, `P+A` creates a new partition
with `A` as a new part. Note that `A` and the ground set of `P`
must be disjoint.
"""
function (+)(P::Partition{T}, A::Set{T}) where T
  @assert length(intersect(P.elements,A))==0 "The added set must be dijsoint from the ground set of the partition."
  sets = parts(P)
  push!(sets,A)
  return PartitionBuilder(sets)
end


"""
`meet(P,Q)` computes the meet of the partitions. This may
also be invoked as `P*Q`.
"""
function meet(P::Partition{T}, Q::Partition{T}) where T
  @assert P.elements==Q.elements "The ground sets of the two partitions must be the same."

  R = Partition(P.elements)
  elist = collect(P.elements)
  n = length(elist)

  for i=1:n-1
    a = elist[i]
    for j=i+1:n
      b = elist[j]
      if in_same_part(P,a,b) && in_same_part(Q,a,b)
        merge_parts!(R,a,b)
      end
    end
  end
  return R
end

"""
For partitions `P` and `Q`, `P*Q` is their meet.
"""
(*)(P::Partition, Q::Partition) = meet(P,Q)


"""
For partitions `P` and `Q`, `P∧Q` is their meet.
"""
(∧)(P::Partition, Q::Partition) = meet(P,Q)



"""
`refines(P,Q)` determines if `P` is a refinement of `Q`. That is,
is every part of `P` a subset of a part of `Q`? The two partitions
must have the same ground set of else an error is thrown.

`refines(P,Q)` can be invoked as `P<=Q`. The variants
`P<Q`, `P>=Q`, and `P>Q` operate as expected. Note that partitions
are only partially ordered by refinement and one can easily construct
partitions `P` and `Q` for which both `P<=Q` and `Q<=P` are false.
"""
function refines(P::Partition{T}, Q::Partition{T}) where T
  @assert P.elements==Q.elements "The two partitions must have the same ground set."

  Pparts = collect(parts(P))
  for S in Pparts
    elts = collect(S)
    n = length(elts)
    for i=1:n-1
      if !in_same_part(Q,elts[i],elts[i+1])
        return false
      end
    end
  end
  return true
end

# Comparison operators based on "is finer". Only a partial order!!
(<=)(P::Partition,Q::Partition) = refines(P,Q)
(<)(P::Partition,Q::Partition) = refines(P,Q) && !(P==Q)
(>=)(P::Partition,Q::Partition) = (Q<=P)
(>)(P::Partition,Q::Partition) = (Q<P)

# include("random_partitions.jl")  # not ready for prime time
include("all_partitions.jl")
include("integer_partition.jl")

end  # end of module
