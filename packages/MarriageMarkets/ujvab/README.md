# MarriageMarkets

[![Build Status](https://travis-ci.org/tobanw/MarriageMarkets.jl.svg?branch=master)](https://travis-ci.org/tobanw/MarriageMarkets.jl)
[![Coverage Status](https://coveralls.io/repos/github/tobanw/MarriageMarkets.jl/badge.svg?branch=master)](https://coveralls.io/github/tobanw/MarriageMarkets.jl?branch=master)

The `MarriageMarkets` package currently provides two marriage market models as Julia types:

- `StaticMatch`: computes the equilibrium of the static frictionless marriage market model from "Who Marries Whom and Why" (Choo & Siow, 2006).
- `SearchMatch`: computes the equilibrium of variants on the search and matching model from "Assortative Matching and Search" (Shimer & Smith, 2000) and the empirical extension in "Marriage Gains" (Goussé, 2014).

`SearchMatch` also allows for inflows of new singles as well as deaths.

## Installation

As described in the manual, to [install unregistered packages][unregistered], enter `pkg` mode in the REPL (by pressing `]`) and add the repository url:

```julia
(v1.0) pkg> add https://github.com/tobanw/MarriageMarkets.jl
```

Julia version 1.0 or higher is required (installation instructions [here][version]).

## Usage

As `SearchMatch` supports a number of model variants, there are specific constructors for the two main types:

* `SearchClosed`: closed-system where agents cycle between singlehood and marriage
* `SearchInflow`: steady-state population is determined by exogenous inflows and type-specific death rates

All models support both unidimensional and multidimensional agent types.
To specify a multidimensional type space, use a `Vector` of `Vector`s, e.g., `[[1,1.5,1.7], [0,1]]`

## Examples

Here are some simple examples of solving models with unidimensional types.
I use [Gadfly][gadfly] to plot the resulting equilibrium objects.

### Static model

```julia
using MarriageMarkets
using Gadfly

n = 50 # number of types
Θ = collect(range(0.1, stop=1.0, length=n)) # type space vector
m = ones(n) ./ n # uniform population measures
f(x,y) = x*y # marital surplus function (per capita)

static_mgmkt = StaticMatch(Θ, Θ, m, m, f)

plot(z=static_mgmkt.matches, Geom.contour, Guide.title("Distribution of matches"))
```

![matches](https://user-images.githubusercontent.com/667531/47978860-d9d14980-e074-11e8-83bd-c172e0045275.png)

The saddle shape indicates positive assortative matching, as expected, due to the supermodular production function `f(x,y) = x*y`.


### Search model

The example below solves a search model with inflows and death.
Then I plot the probabilities of match formation conditional on meeting.

```julia
using MarriageMarkets
using Gadfly

λ, δ = 500.0, 0.05 # arrival rates of meetings and divorce shocks
r = 0.05 # discount rate
σ = 1 # variance of Normally distributed match-specific productivity shocks
n = 50 # number of types
Θ = collect(range(0.1, stop=1.0, length=n)) # type space vector
f(x,y) = x*y # marital production function

γ = ones(n) ./ n # uniform inflows
ψ = ones(n) # uniform death rates

search_mgmkt = SearchInflow(λ, δ, r, σ, Θ, Θ, γ, γ, ψ, ψ, f)

plot(z=search_mgmkt.α, Geom.contour, Guide.title("Match probability conditional on meeting"))
```

![alpha](https://user-images.githubusercontent.com/667531/47978863-e05fc100-e074-11e8-9537-c35ae266aba3.png)


## Testing

In a Julia REPL session, enter `pkg` mode and run `test MarriageMarkets`.


[unregistered]:https://docs.julialang.org/en/latest/stdlib/Pkg/#Adding-unregistered-packages-1
[version]:http://julialang.org/downloads/platform.html
[gadfly]:http://gadflyjl.org/stable/
