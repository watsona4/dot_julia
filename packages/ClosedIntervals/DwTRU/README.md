**Note**: This type does not define interval arithmetic.

ClosedIntervals
===============


[![Build Status](https://travis-ci.org/scheinerman/ClosedIntervals.jl.svg?branch=master)](https://travis-ci.org/scheinerman/ClosedIntervals.jl)

[![Coverage Status](https://coveralls.io/repos/scheinerman/ClosedIntervals.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/scheinerman/ClosedIntervals.jl?branch=master)

[![codecov.io](http://codecov.io/github/scheinerman/ClosedIntervals.jl/coverage.svg?branch=master)](http://codecov.io/github/scheinerman/ClosedIntervals.jl?branch=master)


The `ClosedIntervals` module defines a data type `ClosedInterval` that
represents a set of the form `[a,b] = {x: a <= x <= b}`. Typically, a
`ClosedInterval` is created by specifying its end points:
```julia
julia> using ClosedIntervals

julia> ClosedInterval(3,7)
[3,7]

julia> ClosedInterval(8,2)
[2,8]

julia> a = (6,0)
(6,0)

julia> 5 .. 2  # dot-dot notation works to create a ClosedInterval
[2,5]

julia> 5 ± 2   # a ± b creates the interval from a-b to a+b
[3,7]

julia> ClosedInterval(a)
[0,6]

julia> ClosedInterval(1, 2.3)  # type promotion of end point
[1.0,2.3]
```

This example illustrates a few points.

* First, interval is printed in standard mathematical notation using
square brackets.
* Second, the end points can be specified in either order.
* Third, the interval can be constructed from a tuple.
* Finally, the type of the two end points need not be the same.
Julia's promotion mechanism selects an appropriate
common type for the two end points.


The two end points of the interval may be the same, in which case
it is enough to name only one of the end points:
```julia
julia> ClosedInterval(5)
[5,5]
```

If no arguments are provided to `ClosedInterval` the result is the
unit interval [0,1] with `Float64` end points. Or, if we supply a
type `T`, then the result is again [0,1], but with type `T` end
points.
```julia
julia> ClosedInterval()
[0.0,1.0]

julia> ClosedInterval(Int)
[0,1]

julia> typeof(ans)
ClosedInterval{Int64} (constructor with 1 method)
```

We also provide an empty interval constructed with `EmptyInterval`,
like this:
```julia
julia> X = EmptyInterval()
[]

julia> typeof(X)
ClosedInterval{Float64} (constructor with 1 method)

julia> Y = EmptyInterval(Int)
[]

julia> typeof(Y)
ClosedInterval{Int64} (constructor with 1 method)
```
Notice that empty intervals are printed as a pair of square brackets
with nothing between.

Properties
----------

The functions `left` and `right` are used to retrieve the left and
right end points of an interval. Use `length` to get the length of the
interval (difference of the end points).
```julia
julia> A = ClosedInterval(6,2)
[2,6]

julia> left(A)
2

julia> right(A)
6

julia> length(A)
4
```

Empty intervals have `length` equal to zero.
The `left` and `right` functions applied to empty
intervals throw an error.
Use `isempty` to test if an interval is empty.
```julia
julia> isempty(A)
false

julia> isempty(X)
true
```

To test if a given value lies inside an interval, use `in`:
```
julia> A = ClosedInterval(3,10)
[3,10]

julia> in(5,A)
true

julia> in(1,A)
false

julia> X = EmptyInterval(Int)
[]

julia> in(0,A)
false
```
Notice that testing for membership in an empty interval
always return `false`.



Operations
----------

Two operations are defined for intervals.

* The intersection `*` is the largest interval contained
in both. If the intervals are disjoint, this returns an
empty interval. Also available as `∧`.
* The sum `+` is the smallest interval containing both
(i.e., the join of the intervals).
If the  intervals overlap, then this is the same as their
union. Note that the empty interval serves as an identity
element for this operation. Also available as `∨`.

```julia
julia> A = ClosedInterval(1,5)
[1,5]

julia> B = ClosedInterval(3,7)
[3,7]

julia> A*B
[3,5]

julia> A+B
[1,7]

julia> C = ClosedInterval(1,3)
[1,3]

julia> D = ClosedInterval(5,6)
[5,6]

julia> C*D
[]

julia> C+D
[1,6]
```

Infinite Intervals
------------------

When intervals have end points that are floating points numbers,
it is possible to work with infinite intervals.
Everything works as one might expect.
```julia
julia> A = ClosedInterval(0., Inf)
[0.0,Inf]

julia> B = ClosedInterval(1., -Inf)
[-Inf,1.0]

julia> A*B
[0.0,1.0]

julia> A+B
[-Inf,Inf]

julia> length(A)
Inf

julia> in(2.,A)
true

julia> in(2.,B)
false
```

Comparison
----------

### Equality

The usual comparison operators may be applied to pairs of
intervals. As usual, equality may be checked with `==` (or
`isequal`).


### Subset

Use `issubset(J,K)` to  test if `J` is contained in `K`. The following
comparison operations work as expected:
+ `J ⊆ K` -- subset, same as `issubset(J,K)`
+ `J ⊊ K` -- proper subset
+ `J ⊇ K` -- superset
+ `J ⊋ K` -- proper superset

### Lexicographic total order

We also define `isless` for intervals as follows. An empty interval is
defined to be less than all nonempty intervals. Otherwise, we sort
intervals lexicographically. That is, interval `[a,b]` is less than
`[c,d]` provided either (a) `a<c` or (b) `(a==c) && (b<d)`.

Intervals of mixed type may be compared. For example:
```julia
julia> A = ClosedInterval(1,2)
[1,2]

julia> B = ClosedInterval(1.,2.)
[1.0,2.0]

julia> A==B
true

julia> A = ClosedInterval(-Inf,3.)
[-Inf,3.0]

julia> B = ClosedInterval(3,5)
[3,5]

julia> A < B
true
```

### Completely-to-the-left-of partial order

We use `<<` to test if one interval is completely to the left of another.
That is `[a,b]<<[c,d]` exactly when `b<c`. In this case, comparing an
empty interval to any other yields `false`. Likewise, we use `>>`
to test if one interval is to the right of another.
```julia
julia> A = ClosedInterval(1,5);

julia> B = ClosedInterval(3,8);

julia> C = ClosedInterval(7,9);

julia> A<<B
false

julia> A<<C
true

julia> B<<C
false

julia> C>>A
true

```

## Non-numeric end points

Normally, the end points of a `ClosedInterval` are real numbers
(subtypes of `Real`).
However, we do permit the end point types to be any Julia objects
that can be compared with `<`. For example:
```julia
julia> J = ClosedInterval("charlie", "bravo")
[bravo,charlie]

julia> K = ClosedInterval("oscar", "yankee")
[oscar,yankee]

julia> J+K
[bravo,yankee]

julia> in("romeo", K)
true
```
However, some operations will fail if they rely on numeric
operations. For example:
```julia
julia> length(J)
ERROR: MethodError: `-` has no method matching -(::String, ::String)

julia> J*K
ERROR: MethodError: no method matching zero(::Type{String})
```


<hr>

## `ClosedIntervals` vs `IntervalSets`

The [IntervalSets](https://github.com/JuliaMath/IntervalSets.jl) module also defines a `ClosedInterval` type that
has some notable differences in how intervals are handled.

### Construction

In `ClosedIntervals`, the end points may be specified in either order,
while in `IntervalSets` if the left end point is
greater than the right, an empty interval results.

```julia
julia> using ClosedIntervals

julia> ClosedInterval(1,2) == ClosedInterval(2,1)
true
```

```julia
julia> using IntervalSets

julia> ClosedInterval(1,2) == ClosedInterval(2,1)
false
```

### Union/Join

In the `ClosedIntervals` module, the join `J ∨ K` or `J + K` of two intervals is
the smallest interval containing both. In particular, we permit the join of
disjoint intervals. The intervals may be disjoint.

```
julia> ClosedInterval(1,2) ∨ ClosedInterval(3,4)
[1,4]
```

The `IntervalSets` module provides for the union of intervals.
If the two intervals are disjoint, their set-theoretic union is not an
interval and results in an error.

```julia
julia> ClosedInterval(1,2) ∪ ClosedInterval(3,4)
ERROR: ArgumentError: Cannot construct union of disjoint sets.
```

Note that the intersection (`IntervalSets`) and meet (`ClosedIntervals`) of
two intervals are the same.

### Length/Width

The two modules have different implementations of the `length` function.
* In the `ClosedIntervals` module, `length` is simply the difference between
the right and left end point values.
* In `IntervalSets`, one can only apply `length` to intervals with integer
end points, in which case the `length` is the number of integers in the set.
Instead, use `width` to determine the distance between the end points.

```julia
julia> using ClosedIntervals

julia> length(ClosedInterval(1,4))
3

julia> length(ClosedInterval(1.0,4.0))
3.0
```


```julia
julia> using IntervalSets

julia> length(ClosedInterval(1,4))
4

julia> length(ClosedInterval(1.0,4.0))
ERROR: MethodError: no method matching length(::ClosedInterval{Float64})

julia> width(ClosedInterval(1.0,4.0))
3.0
```
