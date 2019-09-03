# RingLists


[![Build Status](https://travis-ci.org/scheinerman/RingLists.jl.svg?branch=master)](https://travis-ci.org/scheinerman/RingLists.jl)

[![Coverage Status](https://coveralls.io/repos/scheinerman/RingLists.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/scheinerman/RingLists.jl?branch=master)

[![codecov.io](http://codecov.io/github/scheinerman/RingLists.jl/coverage.svg?branch=master)](http://codecov.io/github/scheinerman/RingLists.jl?branch=master)

A `RingList` is a list of distinct values that is
unchanged by rotation. These can be created by giving a list of values
or a one-dimensional array of values:
```julia
julia> a = RingList(1,2,3,4);

julia> b = RingList([2,3,4,1]);

julia> a==b
true
```

## Functions

In this list, `a` stands for a `RingList`.

* `length(a)` gives the number of elements held in the `RingList`.
* `keys(a)` returns an iterator of the elements in `a`.
* `haskey(a,x)` checks if `x` is an element of the `RingList`.
* `Vector(a)` returns a one-dimensional array of
the elements in `a`.
* `Set(a)` returns the elements of `a` (as an unordered collection).
* `a[x]` returns the next element after `x` in `a`.
* `previous(a,x)` returns the element `y` with `a[y]==x`.
* `first(a)` returns an element of `a`; call `first(a,true)` to attempt try to
return the smallest value held in `a`. Fails if `a` is empty.
* `insert!(a,x)` inserts the element `a` into the `RingList`. No guarantee where it will end up.
* `delete!(a,x)` removes `x` from the collection linking together its
predecessor and successor.
* `insertafter!(a,x,y)` inserts `x` into `a` after `y`. For example:

```julia
julia> a = RingList(1,2,3)
RingList{Int64}(1,2,3)

julia> insertafter!(a,99,2)

julia> a
RingList{Int64}(1,2,99,3)
```

* `reverse(a)` returns a new `RingList` with the elements reversed.

```julia
julia> a = RingList(1,2,3,4,5)
RingList{Int64}(1,2,3,4,5)

julia> b = reverse(a)
RingList{Int64}(1,5,4,3,2)
```
