# MarkovChains.jl

[![Build Status](https://travis-ci.org/wangnangg/MarkovChains.jl.svg?branch=master)](https://travis-ci.org/wangnangg/MarkovChains.jl)
[![Coverage Status](https://coveralls.io/repos/github/wangnangg/MarkovChains.jl/badge.svg?branch=master)](https://coveralls.io/github/wangnangg/MarkovChains.jl?branch=master)

This pacakge provides functions to solve continuous time Markov chains for state
probablities or accumulated sojourn times at a certain time point, including
time infinity.

# Tutorial
Here's a detailed [tutorial](docs/tutorial.ipynb) on how to use this package.

# Example
## A birth-death chain
The following example is about solving a 4 states birth-death chain at time 0.1, 1.0, and infinity.

```julia
using MarkovChains
chain = ContMarkovChain()
n0 = add_state!(chain)
n1 = add_state!(chain)
n2 = add_state!(chain)
n3 = add_state!(chain)
add_transition!(chain, n0, n1, 1.0) #transition from n0 to n1 with rate = 1.0
add_transition!(chain, n1, n2, 1.0)
add_transition!(chain, n2, n3, 1.0)
add_transition!(chain, n3, n2, 3.0)
add_transition!(chain, n2, n1, 2.0)
add_transition!(chain, n1, n0, 1.0)
init_prob = sparsevec([1], [1.0])

sol = solve(chain, init_prob, 0.1) #solve at time 0.1
@show state_prob(sol, n1) #probablity of being at state n1 at time 0.1
# state_prob(sol, n1) = 0.08652421409974947

sol = solve(chain, init_prob, 1) 
@show state_prob(sol, n1)
# state_prob(sol, n1) = 0.375

sol = solve(chain, init_prob, Inf)
@show state_prob(sol, n1)
# state_prob(sol, n1) = 0.375
```
## A chain with absorbing states
The following example is about solving a 3 states chain with absorbing states.

```julia
chain = ContMarkovChain()
n1 = add_state!(chain)
n2 = add_state!(chain)
n3 = add_state!(chain)
add_transition!(chain, n1, n2, 2.0)
add_transition!(chain, n2, n3, 4.0)
init_prob = sparsevec([1], [1.0])

sol = solve(chain, init_prob, 0.5)

@show state_prob(sol, n2)
# state_prob(sol, n2) = 0.23254415793482963

@show state_cumtime(sol, n2) #cumulative time spent in state n2
# state_cumtime(sol, n2) = 0.09989410022321275

@show mean_time_to_absorption(chain, init_prob) #you may be interested in MTTA for a chain with absorbing states
# mean_time_to_absorption(chain, init_prob) = 0.75
```


