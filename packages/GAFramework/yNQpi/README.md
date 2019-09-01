# GAFramework: a genetic algorithm framework with multi-threading

[![Build Status](https://travis-ci.org/vvjn/GAFramework.jl.svg?branch=master)](https://travis-ci.org/vvjn/GAFramework.jl) [![Coverage Status](https://coveralls.io/repos/vvjn/GAFramework.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/vvjn/GAFramework.jl?branch=master) [![codecov.io](http://codecov.io/github/vvjn/GAFramework.jl/coverage.svg?branch=master)](http://codecov.io/github/vvjn/GAFramework.jl?branch=master)

GAFramework is a framework for writing genetic algorithms in Julia. It
supports parallelism by calculating crossovers and fitness using
Julia's multi-threading capabilities.

Since GAFramework stores the entire state of your genetic algorithm in
an object, it allows you to save the entire state to file. It allows
you to continue running your GA after you load your state from file or
after you stop at a generation.  It allows you to change parameters
such as crossover/mutation parameters after you stop at a generation
and then continue from where you stopped.

GAFramework is replicable with respect to pseudo-randomness. So, if
you specify a random number generator, GAFramework will fully
replicate your GA run as long as the number of threads used is the
same for both runs.

GAFramework also contains a genetic algorithm implementation that
"minimizes" any function `f : R^n -> R` over a box in a Coordinate
space.

## Installation

`Pkg.add("GAFramework")` or `Pkg.clone("https://github.com/vvjn/GAFramework.jl")`

This requires the JLD package.

## Implementing a GA for a specific problem

To create a GA for a specific problem, we need to create concrete
sub-types of the abstract types `GAModel` and `GACreature`, and then
create relevant functions for the sub-types.

To demonstrate this, we create a GA for optimizing a function over a box in a
Coordinate space, i.e., a function `f : R^n -> R`.

First, we import the `GAFramework` module and import relevant
functions.

```julia
using GAFramework
import GAFramework: fitness, genauxga, crossover, mutate, selection,
randcreature,printfitness, savecreature
```

Next, we create a sub-type of `GAModel`, which contains the function
`f`, the corners of the box (`xmin` and `xmax`), and the span of
the box (`xspan`). It also contains the `clamp` field: if `clamp
= true` then we will clamp mutated or crossovered points back into the
box, so that our solutions will be inside the box;
otherwise, our solutions will not be constrained.

```julia
immutable CoordinateModel{F,T} <: GAModel
    f::F
    xmin::T
    xmax::T
    xspan::T # xmax-xmin
    clamp::Bool
end

function CoordinateModel(f::F,xmin,xmax,clamp::Bool=true) where {F}
        xspan = xmax .- xmin
    CoordinateModel{F,typeof(xspan)}(f,xmin,xmax,xspan,clamp)
end
```

Then, we create a sub-type of `GACreature`, which contains the
"chromosomes" of the creature (`value` field) and the objective value of the
function (`objvalue` field). We calculate the objective value when creating a
`CoordinateCreature{T}` object.

```julia
immutable CoordinateCreature{T} <: GACreature
    value :: T
    objvalue :: Float64
end

CoordinateCreature(value::T, model::CoordinateModel{F,T}) where {F,T} =
    CoordinateCreature{T}(value, model.f(value))
```

Since we are minimizing the objective value, we set `fitness` to be
negative of the objective value. Depending on the selection function
used, `fitness(::GACreature)` might need to be non-negative, be a
probability value, etc. But in general, you would want this function to be
at the very least monotonic with respect to `objvalue`. A further
note: the bulk of the calculation should be relegated to when the
`CoordinateCreature{T}` object is created; the `fitness` function
below, since it will be repeatedly called during selection and
sorting, should be a very fast and simple function such as identity or negation.

```julia
fitness(x::CoordinateCreature) = -x.objvalue
```

The following creates a randomly generated `CoordinateCreature`
object. It creates a random point drawn with uniform probability
from the box. Note: `aux` is used to store auxiliary scratch space in
case we want to minimize memory allocations. `aux` can be created by
overloading the `genauxga(model::CoordinateModel)` function, which is
used to produce memory-safe (with respect to multi-threading) auxiliary scratch
space. In this example, we do not need any scratch space.

```julia
randcreature(m::CoordinateModel{F,T}, aux, rng) where {F,T} =
    CoordinateCreature(m.xmin .+ m.xspan .* rand(rng,length(m.xspan)), m)
```

The following defines the crossover operator. We define a crossover as
the average of two points (not the greatest crossover operator). Note:
we re-use memory from the `z` object when creating
the new `CoordinateCreature`.

```julia
function crossover(z::CoordinateCreature{T}, x::CoordinateCreature{T},
                   y::CoordinateCreature{T}, m::CoordinateModel{F,T},
                   params, curgen, aux, rng) where {F,T}
              z.value[:] = 0.5 .* (x.value .+ y.value)
              CoordinateCreature(z.value, m)
end              
```

The following defines the mutation operator. We draw a vector from a
circular normal distribution, scale it by the box, and shift the
original point with the drawn vector (again, not the greatest mutation
operator).  Clamping is optionally done to restrict points to be
inside the box.

```julia
function mutate(x::CoordinateCreature{T}, m::CoordinateModel{F,T},
                params, curgen, aux, rng) where {F,T}
    if rand(rng) < params[:rate]            
        x.value .+= 0.01 .* m.xspan .* randn(rng,length(x.value))
        if m.clamp
            x.value .= clamp.(x.value, m.xmin, m.xmax)
        end
        CoordinateCreature(x.value, m)
    else
        x
    end
end
```

We use tournament selection as our selection operator.

```julia
selection(pop::Vector{<:CoordinateCreature}, n::Integer, rng) =
    selection(TournamentSelection(2), pop, n, rng)
```

This defines how to print details of our creature in a compressed form.

```julia
printfitness(curgen::Integer, x::CoordinateCreature) =
    println("curgen: $curgen value: $(x.value) obj. value: $(x.objvalue)")
```

This defines how to save our creature to file. `GAFramework` will save
the best creature to file using this function.

```julia
savecreature(file_name_prefix::AbstractString, curgen::Integer,
             creature::CoordinateCreature, model::CoordinateModel) =
    save("$(file_name_prefix)_creature_$(curgen).jld", "creature", creature)
```

## Running the GA

That takes care of how to implement our problem using
`GAFramework`. Now, we define our problem by creating a
`CoordinateModel`.

For fun, we want to minimize the function `x sin(1/x)` over the
`[-1,1]` interval.

```julia
model = CoordinateModel(x -> x[1]==0 ? 0.0 : x[1] * sin(1/x[1]), [-1.0], [1.0])
```

Or, we want to minimize the function `<x, sin(1/x)>` in 2D
Euclidean space over the `[-1,1]^2` rectangle.

```julia
model = CoordinateModel(x -> any(x.==0) ? 0.0 : dot(x, sin.(1./x)),
                         [-1.,-1.], [1.,1.])
```

Or, we want to minimize the function `|x - (0.25,0.25,0.5,0.5,0.5)|_1` in
5-dimensional Euclidean space over the `[-1,1]^5` box.

```julia
x0 = [0.25,0.25,0.5,0.5,0.5]
model = CoordinateModel(x -> norm(x-x0,1),
                         [-1.,-1.,-1.,-1.,-1], # minimum corner
                         [1.,1.,1.,1.,1]) # maximum corner in box
```

Here, we create the GA state, with population size 1000, maximum
number of generations 100, fraction of elite creatures 0.01, and
mutation rate 0.1, printing the objective value every 10
iterations. The `GAState` function generates the population and
`state` contains all data required to start/restart a GA.  Each
generation, the GA will create children (using `crossover`) from
selected (using `selection`) parents, replace the non-elites in the
current generation with the children (with respect to `fitness`), and
then mutate everyone in the population (using `mutate`).

```julia
state = GAState(model, ngen=100, npop=1000, elite_fraction=0.01,
                       mutation_params=Dict(:rate=>0.1),
                       print_fitness_iter=10)
```

This runs the GA and we are done.

```julia
ga(state)
````

`state.pop[1]` gives you the creature with the best fitness.

A version of `CoordinateModel` and `CoordinateCreature` are included `GAFramework`. It can be used by executing the statement `using GAFramework.CoordinateGA`.

## Restarting

After we finish a GA run using `ga(state)`, if we decide that we
want to continue optimizing for a few more generations, we can do the
following.  Here, we change maximum number of generations to 200, and
then restart the GA, continuing on from where the GA stopped earlier.

```julia
state.ngen = 200

ga(state)
```

## Replicability with respect to pseudo-randomness

Although `GAFramework` uses pseudo-random numbers for many operations, we
can replicate a GA run using the `baserng` option and by using only the random number
generators provided by the functions to generate random numbers. Setting `baserng` to be an 
object that is a sub-type of `AbstractRNG`
will percolate it throughout the GA, allowing us to replicate a run. By default, `baserng` is
set to `Base.GLOBAL_RNG`.

```julia
state1 = GAState(model, ngen=100, npop=1000, elite_fraction=0.01,
                       mutation_params=Dict(:rate=>0.1),
                       print_fitness_iter=10, baserng=MersenneTwister(12))
best1 = ga(state1)

state2 = GAState(model, ngen=100, npop=1000, elite_fraction=0.01,
                       mutation_params=Dict(:rate=>0.1),
                       print_fitness_iter=10, baserng=MersenneTwister(12))
best2 = ga(state2)

println(all([getfield(state1,x) == getfield(state2,x) for x in fieldnames(GAState)]))
# true
println(best1 == best2)
# true
```

## Saving creature to file

We can save the creature to file every 10 iterations using the following.

```julia
state = GAState(m, ngen=100, npop=1000, elite_fraction=0.01,
                mutation_params=Dict(:rate=>0.1), print_fitness_iter=10,
                save_creature_iter=10, file_name_prefix="minexp_6000")
```

After we finish a GA run using `ga(state)`, and we decide that we
want to save the best creature to file afterwards, we can do the following.

```julia
savecreature("minexp_6000", state.ngen, state.pop[1], model)
```

## Saving GA state to file

This save the full GA state to file every 100 iterations using the
following. Note: unfortunately, this doesn't work with
`CoordinateModel{F,T}` since it contains the function `f::F` as a field. It should
work for other types that do not contain functions.

```julia
state = GAState(m, ngen=100, npop=1000, elite_fraction=0.01,
                mutation_params=Dict(:rate=>0.1), print_fitness_iter=10,
                save_state_iter=100, file_name_prefix="minexp_6000")
```

If something happens during the middle of running `ga(state)`, we can
reload the state from file from the 100th generation as follows, and
then restart the GA from the saved generation.

```julia
state = loadgastate("minexp_6000_state_100.jld")

ga(state)
```

We can also directly save the state using the following.

```julia
savegastate("minexp_6000", state.ngen, state)
```
