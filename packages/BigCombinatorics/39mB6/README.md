# BigCombinatorics


[![Build Status](https://travis-ci.org/scheinerman/BigCombinatorics.jl.svg?branch=master)](https://travis-ci.org/scheinerman/BigCombinatorics.jl)


[![codecov.io](http://codecov.io/github/scheinerman/BigCombinatorics.jl/coverage.svg?branch=master)](http://codecov.io/github/scheinerman/BigCombinatorics.jl?branch=master)



This is an implementation of various combinatorial functions.
These functions *always* return `BigInt` values. This convention
is signaled by the fact that these functions' names begin
with a capital letter.

## Rationale

If we want to calculate 20!, it's easy enough to do this:
```julia
julia> factorial(20)
2432902008176640000
```
However, for 100!, we see this:
```julia
julia> factorial(100)
ERROR: OverflowError: 100 is too large to look up in the table
Stacktrace:
 [1] factorial_lookup(::Int64, ::Array{Int64,1}, ::Int64) at ./combinatorics.jl:19
 [2] factorial(::Int64) at ./combinatorics.jl:27
 [3] top-level scope at none:0
```
The problem is that 100! is too big to fit in an `Int` answer. Of course,
we could resolve this problem this way:
```julia
julia> factorial(big(100))
93326215443944152681699238856266700490715968264381621468592963895217599993229915608941463976156518286253697920827223758251185210916864000000000000000000000000
```

We take a different approach. We shouldn't have to worry about how large
our arguments may be before a combinatorial function overflows. Instead,
let's assume the result is *always* of type `BigInt` so the calculation
will not be hampered by this problem.



## Functions

+ `Fibonacci(n)` returns the `n`-th Fibonacci number with `Fibonacci(0)==0`
and `Fibonacci(1)==1`.
+ `Factorial(n)` returns `n!` and `Factorial(n,k)` returns `n!/k!`.
+ `FallingFactorial(n,k)` returns `n*(n-1)*(n-2)*...*(n-k+1)`.
+ `RisingFactorial(n,k)` returns `n*(n+1)*(n+2)*...*(n+k-1)`.
+ `DoubleFactorial(n)` returns `n!!`.
+ `Catalan(n)` returns the `n`-th Catalan number.
+ `Derangements(n)` returns the number of derangements of
an `n`-element set.
+ `Binomial(n,k)` returns the number of `k`-element subsets
of an `n`-element set.
+ `MultiChoose(n,k)` returns the number of `k`-element
*multisets* that can be formed using the elements of
an `n`-element set. **Warning**: This is not the same
as `Multinomial`.
+ `Multnomial(vals)` returns the multinomial coefficient where
the top index is the sum of `vals`. Here, `vals` may either be a
vector of integers or a comma separated list of arguments.
In other words, both `Multinomial([3,3,3])` and `Multinomial(3,3,3)`
return the multinomial coefficient with top index `9` and bottom
indices `3,3,3`. The result is `1680`. **Warning**: This is
not the same as `MultiChoose`.
+ `Bell(n)` returns the `n`-th Bell number, i.e., the number
of partitions of an `n`-element set.
+ `Stirling1(n,k)` returns the *signed* Stirling number of the
first kind.
+ `Stirling2(n,k)` returns the Stirling number of the second
kind, i.e., the number of partitions of an `n`-element set into
`k`-parts (nonempty).
+ `Fibonacci(n)` returns the `n`-th Fibonacci number
with `Fibonacci(0)==0` and `Fibonacci(1)==1`.
+ `IntPartitions(n)` returns the number of partitions of the integer `n`
and `IntPartitions(n,k)` returns the number of partitions of the integer
`n` with exactly `k` parts.
+ `IntPartitionsDistinct(n)` returns the number of partitions of `n` into
*distinct* parts and `IntPartitionsDistinct(n,k)` returns the number of
partitions of `n` into `k` *distinct* parts.
+ `Euler(n)` returns the `n`-th Euler number.
+ `Eulerian(n,k)` returns the number of permutations of `1:n` with `k`
ascents.
+ `PowerSum(n,k)` returns the sum `1^k + 2^k + ... + n^k`.

## Implementation


These function have nice recursive properties that we
exploit to make the code as simple as possible.
In many (but not all) of these functions we cache the result
of the calculation to avoid combinatorial explosion in the
recursion. In those cases, we don't compute the same result twice.


The following functions can be used to manage the saved values.

* `BigCombinatorics.cache_report()` prints out the number of values
stored in the cache for each function.
* `BigCombinatorics.cache_clear(func)` clears all values stored for
a specific function.
* `BigCombinatorics.cache_clear()` clears all values in the cache.
