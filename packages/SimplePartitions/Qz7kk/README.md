# SimplePartitions


[![Build Status](https://travis-ci.org/scheinerman/SimplePartitions.jl.svg?branch=master)](https://travis-ci.org/scheinerman/SimplePartitions.jl)

[![Coverage Status](https://coveralls.io/repos/scheinerman/SimplePartitions.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/scheinerman/SimplePartitions.jl?branch=master)

[![codecov.io](http://codecov.io/github/scheinerman/SimplePartitions.jl/coverage.svg?branch=master)](http://codecov.io/github/scheinerman/SimplePartitions.jl?branch=master)




Module for set partitions. We define a
`Partition` to be a wrapper around the `DisjointUnion` type defined
in the `DataStructures` module, but with a bit more functionality.

**New**: We also include `IntegerPartition` too! (See below.)


## Partition Constructor

A new `Partition` is created by specifying the ground set. That is, if `A`
is a `Set{T}` (for some type `T`) or an `IntSet`, then `Partition(A)` creates
a new `Partition` whose ground set is `A` and the parts are singletons.
```julia
julia> using ShowSet
WARNING: Method definition show(Base.IO, Base.Set) ...
WARNING: Method definition show(Base.IO, Base.IntSet) ...

julia> using SimplePartitions

julia> A = Set(1:10)
{1,2,3,4,5,6,7,8,9,10}

julia> P = Partition(A)
{{9},{6},{5},{8},{1},{3},{2},{10},{7},{4}}
```
The parameter to `Partition` may also be a list (one-dimensional array) or
a positive integer `n`, in which case a partition of the set {1,2,...,n} is
created.

### Construct from a set of sets

If `S` is a set of sets then `PartitionBuilder(S)` creates
a new partition whose parts are the sets in `S`. The
sets in `S` must be nonempty and pairwise disjoint.

### Construct from a `Permutation`

If `p` is a `Permutation`, then `Partition(p)` creates a new
partition whose parts are the cycles of `p`.

### Construct from a `Dict`

If `d` is a dictionary, the `Partition(d)` creates a new
partition whose elements are the keys of `d` in which
two elements `a` and `b` are in the same part if and only
if `d[a] == d[b]`.

## Functions

+ `num_elements(P)`: returns the number of elements in the ground
set of `P`.
+ `num_parts(P)`: returns the number of parts in `P`.
+ `parts(P)`: returns the set of the parts in this partition.
+ `collect(P)` returns a one-dimensional array containing the parts.
+ `ground_set(P)`: returns (a copy of) the ground set of `P`.
+ `in(a,P)`: test if `a` (element) is in the ground set of `P`.
+ `in(A,P)`: test if `A` (set) is a part of `P`.
+ `merge_parts!(P,a,b)`: Modify `P` by merging the parts of `P` that
contain the elements `a` and `b`. This may also be called with a
list for the second argument: `merge_parts!(P,[a,b,...])`.
+ `in_same_part(P,a,b)`: returns `true` if `a` and `b` are in the same
part of `P`.
+ `find_part(P,a)`: returns the set of elements in `P`
that are in the same part as `a`.

## Operations

+ `join(P,Q)` returns the join of partitions `P` and `Q`. This can also
be invoked as `P+Q` or as `P∨Q`.
+ `meet(P,Q)` returns the meet of the partitions. This can also be
invoked as `P*Q` or as `P∧Q`.
+ `P+x` where `P` is a partition and `x` is a new element creates a
new partition in which `x` is added as a singleton.
+ `P+A` where `P` is a partition and `A` is a set of elements
(that are disjoint from the elements already in `P`) creates a new
partition by adding `A` as a part.

## Relations

+ `P==Q` determines if `P` and `Q` are equal partitions.
+ `P<=Q` determines if `P` is a refinement of `Q`. That is, we return `true`
if each part of `P` is a subset of a part of `Q`. Note that `P` and `Q` must
have the same ground set or else an error is thrown. The variants
`P<Q`, `P>=Q`, and `P>Q` are available with the expected meanings. Calling
`refines(P,Q)` is the same as `P<=Q`.

## Generating all partitions of a set

+ `all_partitions(A::Set)` creates a `Set` containing all possible
partitions of `A`.
+ `all_partitions(n::Int)` creates a `Set` containing all possible
partitions of the set `{1,2,...,n}`.

Both of these take an optional second argument `k` to specify that
only partitions with exactly `k` parts should be returned.


## Examples

Note: Sets are nicely displayed here because we invoked
`using ShowSet`.

```julia
julia> A = Set(["alpha", "bravo", "charlie", "delta", "echo"])
{alpha,bravo,charlie,delta,echo}

julia> P = Partition(A)
{{delta},{echo},{charlie},{bravo},{alpha}}

julia> merge_parts!(P,"alpha", "bravo")

julia> merge_parts!(P,"echo", "bravo")

julia> merge_parts!(P,"charlie", "delta")

julia> P
{{charlie,delta},{alpha,bravo,echo}}

julia> Q = Partition(A);

julia> merge_parts!(Q,"alpha", "echo")

julia> merge_parts!(Q,"delta","alpha")

julia> Q
{{charlie},{bravo},{alpha,delta,echo}}

julia> P+Q
{{alpha,bravo,charlie,delta,echo}}

julia> P*Q
{{delta},{charlie},{bravo},{alpha,echo}}
```
<hr>

## Integer Partitions

The type `IntegerPartition` represents a partition of an integer.
These can be constructed either from a one-dimensional array of
integers or as individual arguments:
* `IntegerPartition([a,b,c,...])` or
* `IntegerPartition(a,b,c,...)`

### Operations/Functions

* `parts(P)` returns a list containing the parts.
* `sum(P)` returns the sum of the parts.
* `num_parts(P)` returns the number of parts.
* `Ferrers(P)` prints a Ferrer's diagram of `P`.
* `conj(P)` or `P'` returns the Ferrer's conjugate of `P`
* `P+Q` returns the concatenation of `P` and `Q`:
```julia
julia> P = IntegerPartition(2,2,4)
(4+2+2)

julia> Q = IntegerPartition(5,2,1)
(5+2+1)

julia> P+Q
(5+4+2+2+2+1)
```


<hr>

### To do list

+ Create `RandomPartition(n)` [and `RandomPartition(Set)`].
