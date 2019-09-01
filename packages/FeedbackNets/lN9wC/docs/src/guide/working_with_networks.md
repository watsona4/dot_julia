# Working with networks

There are several points to keep in mind while working with feedback networks.

## Slicing

Both `FeedbackChain`s and `FeedbackTree`s support slicing like a normal Flux
`Chain` in order to select a subset of operations in the network.

```jldoctest; setup = :(using Flux, FeedbackNets)
julia> net = FeedbackChain(
           Merger("s1", Dense(5,10), +),
           Dense(10,5),
           Splitter("s1"),
           Dense(5,1)
       )
FeedbackChain(Merger("s1", Dense(5, 10), +), Dense(10, 5), Splitter("s1"), Dense(5, 1))

julia> net[1]
Merger("s1", Dense(5, 10), +)

julia> net[1:2]
FeedbackChain(Merger("s1", Dense(5, 10), +), Dense(10, 5))
```

This is convenient to trace the information flow through the network by applying
a subset of layers at a time. However, by doing this you run the risk of
selecting some `Merger`s that get input from `Splitter`s which are not in your
selected slice. Accordingly, the states required to calculate the next timestep
are not added to the dictionary any more. Slicing should therefore be used with
care.

## Validating names

In order to test whether all inputs required by `Merger`s in a network are
actually provided by corresponding `Splitter`s, you can use the function
[`namesvalid`](@ref).

If each `Splitter` has a unique name and each `Merger` name corresponds to a
`Splitter`, validation will succeed.

```@example
using Flux, FeedbackNets # hide
namesvalid(FeedbackChain(
    Merger("s1", Dense(5,10), +),
    Dense(10, 5),
    Splitter("s1")
))
```

However, if one of these constraints is violated, validation fails.

```@example
using Flux, FeedbackNets # hide
namesvalid(FeedbackChain(
    Merger("s1", Dense(5,10), +),
    Dense(10, 5),
    Splitter("s2")
))
```

## Moving to GPU

In order to perform computations on a GPU, the usual Flux syntax can be used to
move the model:

```julia
julia> net = net |> gpu
```

However, this does not work natively for dictionaries and accordingly also not
for feedback networks wrapped in a `Flux.Recur` where the state is encoded as a
dictionary. In order to move a dictionary to the GPU, generate a new `Dict` with
the same keys and values moved to GPU:

```julia
julia> state = Dict(key => gpu(val) for (key, val) in pairs(state))
```

## Reset

A `Flux.Recur` will keep accumulating gradients via its internal state, also
across sequences. In order to prevent this and start from a fresh state for each
new sample, you should call `Flux.reset!()` on your model after each input
sequence. Typically, you would do this whenever you calculate the loss or
accuracy. See
[here](https://fluxml.ai/Flux.jl/stable/models/recurrence/#Truncating-Gradients-1)
for details.
