# Simple Random


[![Build Status](https://travis-ci.org/scheinerman/SimpleRandom.jl.svg?branch=master)](https://travis-ci.org/scheinerman/SimpleRandom.jl)

[![Coverage Status](https://coveralls.io/repos/scheinerman/SimpleRandom.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/scheinerman/SimpleRandom.jl?branch=master)

[![codecov.io](http://codecov.io/github/scheinerman/SimpleRandom.jl/coverage.svg?branch=master)](http://codecov.io/github/scheinerman/SimpleRandom.jl?branch=master)




This is a collection of Julia functions to make
random things. Part of the `SimpleWorld` collection.



## Random unit vector

`random_unit_vector(d)` returns a random `d`-dimensional unit vector.

## Random subsets

`random_subset` creates a random subset with the following variations:
+ `random_subset(A)`: create a random subset of `A`  with each element
included with probability 0.5.
+ `random_subset(A,k)`: create a random `k`-element
subset of `A`.
+ `random_subset(n)`: create a random subset of `1:n`.
+ `random_subset(n,k)`: create a random `k`-element
subset of `1:n`.

## Random selection

`random_choice` is used to select a number or object at random
according to some (finite, discrete distribution). We provide two
variants:

+ `random_choice(weights)` randomly chooses a value from `1` to `n`,
where `n` is the number of elements in `weights`. The probability
that `k` is chosen is proportional to `weights[k]`. The `weights`
must be nonnegative and not all zero.
+ `random_choice(dict)` choose a random key `k` from `dict` with weight
proportional to `dict[k]`. Thus, `dict` must be of type
`Dict{S, T<:Real}`.


#### Notes

+ No error checking is done on the input. An error
might be raised for bad input, but that's not
guaranteed.
+ The implementation might be improved. If the size
of the argument is small, this is efficient enough.
But if `wts` (or `d`) has many elements, I probably
should do some sort of binary search through the vector
of cumulative sums.

## Histogram

The function `histplot(x)` creates a `PyPlot` bar chart giving a histogram
of the values in the list `x`. Called as `histplot(x,n)` creates such
a plot with `n` bins.

**Note**: This function has been moved to a separate file `histplot.jl` in
the `src` directory. I've been having some issues with `PyPlot` and
this function doesn't really apply to creating random things (but
  rather to visualizing them).

## Distributions

**Note**: I'm just wrapping stuff found in  `Distributions`.
Probably better just to use that package directly.

#### Binomial

`binom_rv(n,p)` generates a random binomial random value. `p` defaults
to `0.5`.

#### Poisson

`poisson_rv(lambda)` returns a Poisson random value with mean `lambda`
(which defaults to `1.0`).

#### Exponential

`exp_rv(theta)` returns an exponential random value with
mean `theta` (which defaults to `1.0`).


# Random Variable Type

The `RV` type represents a random variable *with finite support*; that is,
the set of possible values produced by the random variable is finite. This
rules out continuous random variables and discrete random variables with
infinite support such as Poisson random variables.

## Defining a random variable

The user needs to specify the value type of the random variable
(which needs to be a `Number` type) and the data type for the probabilities
(which needs to be a `Real` type such as `Float64` or `Rational{Int}`).

For example, to define a random variable whose values are integers and
whose probabilities are rational numbers, we do this:
```julia
julia> using SimpleRandom

julia> X = RV{Int, Rational{Int}}()
RV{Int64,Rational{Int64}} with 0 values
```

Now let's imagine that we want the values of `X` to be in the
set {1,2,3} with probabilities 1/2, 1/4, and 1/4 respectively.
We can specify this in two ways.

First, we can directly enter the probabilities like this:
```julia
julia> X = RV{Int, Rational{Int}}()
RV{Int64,Rational{Int64}} with 0 values

julia> X[1]=1//2
1//2

julia> X[2]=1//4
1//4

julia> X[3]=1//4
1//4

julia> report(X)
1   1//2
2   1//4
3   1//4
```

Alternatively, we can enter values and have them automatically scaled
so that they add to 1.
```julia
julia> X = RV{Int, Rational{Int}}()
RV{Int64,Rational{Int64}} with 0 values

julia> X[1] = 2
2

julia> X[2] = 1
1

julia> X[3] = 1
1

julia> report(X)
1	  1//2
2	  1//4
3	  1//4
```

Rescaling happens automatically any time the user/computer wants to
access the probability associated with a value. In this case, the
`report` function prints out the probabilities associated with each
value so the rescaling took place behind the scenes then it was invoked.

Continuing this example, if we now enter `X[4]=1//2`, the probabilities
no longer sum to 1, so if we request the probability associated with a value,
the rescaling takes place.
```julia
julia> X[4] = 1//2
1//2

julia> X[4]
1//3

julia> report(X)
1	 1//3
2	 1//6
3	 1//6
4	 1//3
```

In summary, `X[v]=p` assigns probability `p` to the value `v`. Retrieving
a value invokes a rescaling operation (if needed) before the value is
returned. Note that if `v` is a value that has not been assigned a
probability, then `0` is returned.


## Functions

The following functions are provided:

+ `E(X)` returns the expected value of `X`.
+ `Var(X)` returns the variance of `X`.
+ `length(X)` returns the number of values to which probabilities
have been assigned.
+ `vals(X)` returns an iterator to the values associated with `X`.
+ `probs(X)` returns an iterator to the probabilities associated
with values in `X`.
+ `report(X)` prints a table consisting of the values and their
associated probabilities.
+ `random_choice(X)` returns a random value `v` of `X` at random
with probability `X[v]`. This function is not efficient.  Compare these
timings for generating an array of ten thousand binomial random
values:

```julia
julia> X = Binomial_RV(20,.5)
RV{Int64,Float64} with 21 values

julia> tic(); A = [ random_choice(X) for _=1:10_000 ]; toc();
elapsed time: 0.230939433 seconds

julia> tic(); B = [ binom_rv(20,.5) for _=1:10_000]; toc();
elapsed time: 0.017233562 seconds
```

## Operations

+ `a*X` where `a` is a number creates a new random variable
by multiplying the values in `X` by `a`.
+ `X+Y` creates a new random variable that represents the sum
of the random variables `X` and `Y` considered as independent.
Note that `2*X` is *not* the same as `X+X`.
+ `X-Y` is the difference of independent `X` and `Y`.

## Pre-made random variables

+ `Uniform_RV(n)` creates a random variable whose values are
in `1:n` each with probability `1//n`.
+ `Bernoulli_RV(p)` creates a random variable whose value is `0`
with probability `1-p` and `1` with probability `p`.
+ `Binomial(n,p)` creates a random variable whose values are in `0:n`
with probability given by the binomial distribution. That is, the value
`k` has probability `binomial(n,k)*p^k*(1-p)^(n-k)`.
