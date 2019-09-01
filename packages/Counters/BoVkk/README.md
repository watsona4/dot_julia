# Counters

[![Build Status](https://travis-ci.org/scheinerman/Counters.jl.svg?branch=master)](https://travis-ci.org/scheinerman/Counters.jl)

[![Coverage Status](https://coveralls.io/repos/scheinerman/Counters.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/scheinerman/Counters.jl?branch=master)

[![codecov.io](http://codecov.io/github/scheinerman/Counters.jl/coverage.svg?branch=master)](http://codecov.io/github/scheinerman/Counters.jl?branch=master)



We often want to count things and a way to do that is to create a dictionary
that maps objects to their counts. A `Counter` object simplifies that
process. Say we want to count values of type `String`. We would
create a counter for that type like this:
```julia
julia> c = Counter{String}()
Counter{String} with 0 entries
```

The two primary operations for a `Counter` are value increment and
value retrieval. To increment the value of a counter we do this:
```julia
julia> c["hello"] += 1
1
```
To access the count, we use square brackets:
```julia
julia> c["hello"]
1

julia> c["bye"]
0
```
Notice that we need not worry about whether or not a key is
already known to the `Counter`. If presented with an unknown key,
the `Counter` assumes its value is `0`.

A `Counter` may be assigned to like this `c["alpha"]=4` but
the more likely use case is `c["bravo"]+=1` invoked each
time a value, such as `"bravo"` is encountered.


### Counting the elements of a list

The function `counter` (lowercase 'c') counts the element of a list/array
or set. The multiplicity of an element is the number of times it
appears in the list.
```julia
julia> A = [ "alpha", "bravo", "alpha", "gamma" ];

julia> C = counter(A);

julia> showall(C)
Counter{String} with these nonzero values:
alpha ==> 2
bravo ==> 1
gamma ==> 1

julia> counter(eye(3))
SimpleTools.Counter{Float64} with 2 entries:
  0.0 => 6
  1.0 => 3
```

### Addition of counters

If `c` and `d` are counters (of the same type of object) their sum
`c+d` creates a new counter by adding the values in `c` and `d`. That
is, if `a=c+d` and `k` is any key, then `a[k]` equals `c[k]+d[k]`.


### Incrementing

To increment the count of an item `x` in a counter `c` we may either
use `c[x]+=1` or the increment function like this: `incr!(c,x)`.

The increment function `incr!` is more useful for incrementing a
collection of items. Use `incr!(c,items)` to add 1 to the count
for each element held in `items`. If an element is present in `items`
multiple times, its count is incremented for each occurrence.

```julia
julia> c = Counter{Int}()
SimpleTools.Counter{Int64} with 0 entries

julia> items = [1,2,3,4,1,2,1]
7-element Array{Int64,1}:
 1
 2
 3
 4
 1
 2
 1

julia> incr!(c,items)

julia> showall(c)
Counter{Int64} with these nonzero values:
Counter{Int64} with these nonzero values:
1 ==> 3
2 ==> 2
3 ==> 1
4 ==> 1
```

In addition, `incr!` may be used to increment one counter
by the amount held in another. Note that it's the first argument `c`
that gets changed; there is no effect on the second argument `d`.

**Note**: `incr!(c,d)` and `c += d` have the same effect, but the first
is more efficient.
```julia
julia> d = Counter{Int}();

julia> d[1] = 1;;

julia> d[5] = 1;

julia> incr!(c,d)

julia> showall(c)
Counter{Int64} with these nonzero values:
1 ==> 4
2 ==> 2
3 ==> 1
4 ==> 1
5 ==> 1
```


### More functions

* `sum(c)` returns the sum of the values in `c`; that is, the total
of all the counts.
* `length(c)` returns the number of values held in `c`. Note that
this might include objects with value `0`.
* `nnz(c)` returns the number of nonzero values held
in `c`.
* `keys(c)` returns an iterator for the keys held by `c`.
* `values(c)` returns an iterator for the values held by `c`.
* `showall(c)` gives a print out of all the keys and their nonzero
values in `c`.
* `clean!(c)` removes all keys from `c` whose value is `0`. This
won't change its behavior, but will free up some memory.

In addition, we can convert a `Counter` into a one-dimensional
array in which each element appears with its appropriate multiplicity
using `collect`:

```julia
julia> C = Counter{Int}()
SimpleTools.Counter{Int64} with 0 entries

julia> C[3] = 4
4

julia> C[5] = 0
0

julia> C[-2] = 2
2

julia> collect(C)
6-element Array{Int64,1}:
  3
  3
  3
  3
 -2
 -2

julia> collect(keys(C))
3-element Array{Int64,1}:
  3
 -2
  5
```

### Average value

If the objects counted in `C` are numbers, then we compute the weighted
average of those numbers with `mean(C)`.
```julia
julia> C = Counter{Int}()
SimpleTools.Counter{Int64} with 0 entries

julia> C[2] = 3
3

julia> C[3] = 7
7

julia> mean(C)
2.7
```

### Hashing

`hash(C::Counter)` returns a hash value for the `C`. Note that
`clean!` is applied to `C` before computing the hash. This is
done to ensure that equal counters give the same hash value.

May also be invoked as `hash(C::Counter, h::Uint)`.

### It's `Associative`

A `Counter` is a subtype of `Associative` and therefore we can
use methods such as `keys` and/or `values` to get iterators to
those items.

### CSV Printing
The function `csv_print` writes a `Counter` to the screen in
comma-separated format. This can be readily used for importing
into a spreadsheet.
```julia
julia> C = Counter{Float64}()
SimpleTools.Counter{Float64} with 0 entries

julia> C[3.4]=10
10

julia> C[2.2]=3
3

julia> csv_print(C)
2.2, 3
3.4, 10
```



### Counting in parallel

See the `parallel-example` directory for an illustration of how to
use `Counters` in multiple parallel processes.
