# Getting started

Sometimes an example says more than a thousand words. So let's start with one.

## Simple Example

This is a basic demontration of how to use the package:

```@repl
using MonteCarloObservable
obs = Observable(Float64, "myobservable")
add!(obs, 1.23) # add measurement
obs
push!(obs, rand(4)) # same as add!
length(obs)
timeseries(obs)
obs[3] # conventional element accessing
obs[end-2:end]
add!(obs, rand(995))
mean(obs)
error(obs) # one-sigma error of mean (binning analysis)
saveobs(obs, "myobservable.jld")
```

## Creating `Observable`s



**TODO:** mention all important keywords
**TODO:** mention `alloc` keyword and importance of preallocation.
**TODO:** mention `@obs` and `@diskobs` macros