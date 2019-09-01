# Getting Started

FeedbackNets is a Julia package based on Flux. If you are new to Julia, there
are great learning resources [here](https://julialang.org/learning/) and the
[documentation](https://docs.julialang.org/) is helpful too. In order to get to
know Flux, have a look at their [website](https://fluxml.ai/) and
[documentation](https://fluxml.ai/Flux.jl/stable/).

## Installation

The package can be installed using `Pkg.add()`

```julia
using Pkg
Pkg.add("FeedbackNets")
```

or using the REPL shorthand

```julia
] add FeedbackNets
```

The package depends on `Flux`. `CuArrays` is required for GPU support.


## Basic Usage

Once the package is installed, you can access it with Julia's package manager:

```julia
using FeedbackNets
```

Typically, you'll want to load `Flux` as well for its network layers:

```julia
using Flux
```

In Flux, you would build a (feedforward) deep network by concatenating layers in
a `Chain`. For example, the following code generates a two-layer network that
maps 10 input units on 20 hidden units (with ReLU-nonlinearity) and maps these
to 2 output units:

```julia
net = Chain(
    Dense(10, 20, relu),
    Dense(20, 2)
)
```

This network can be applied to an input like any function:

```julia
x = randn(10)
y = net(x)
```

In order to construct a deep network with feedback, you can use a `FeedbackChain`,
similar to the standard Flux `Chain`. The difference between a normal `Chain`
and a `FeedbackChain` is that the latter knows how to treat two specific types
of layers: `Merger`s and `Splitter`s.

Imagine that in the network above, we wanted to provide a feedback signal from
the two-unit output layer and change activations in the hidden layer based on it.
This requires two steps: first we need to retain the value of that layer, second
we need to project it back to the hidden layer (e.g., through another `Dense`
layer) and add it to the activations there.

The first part is handled by a `Splitter`. Essentially, whenever the `FeedbackChain`
encounters a `Splitter`, it saves the output of the previous layer to a dictionary.
This way, it can be reused in the next timestep. The second part is handled by a
`Merger`. This layer looks up the value that the `Splitter` saved to the dictionary,
applies some operation to it (in our case, the `Dense` layer) and merges the
result into the forward pass (in our case, by addition):

```julia
net = FeedbackChain(
    Dense(10, 20, relu),
    Merger("split1", Dense(2, 20), +),
    Dense(20, 2),
    Splitter("split1")
)
```

Note that the name `"split1"` is used by both `Merger` and `Splitter`. This is
how the `Merger` knows which value from the state dictionary to take. But what
happens during the first feedforward pass? The network has not yet encountered
the `Splitter`, so how does the `Merger` get its value? When a `FeedbackChain`
is applied to an input, it expects to get a dictionary as well, which the user
needs to generate for the first timestep. The `FeedbackChain` returns the updated
dictionary as well as the output of the last layer.

```julia
state = Dict("split1" => zeros(2))
x = randn(10)
state, out = net(state, x)
```

If the user does not want to handle the state manually, they can wrap the net in
a Flux `Recur`, essentially treating the whole network like on recurrent cell:

```julia
using Flux: Recur
net = Recur(net, state)
output = net.([x, x, x])
```
