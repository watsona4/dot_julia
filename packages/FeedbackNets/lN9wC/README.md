# FeedbackNets.jl

Deep and convolutional neural networks with feedback operations in Flux.

![MIT license badge](https://img.shields.io/badge/license-MIT-green.svg)
[![Build Status](https://travis-ci.org/cJarvers/FeedbackNets.jl.svg?branch=master)](https://travis-ci.org/cJarvers/FeedbackNets.jl)
[![Coverage Status](https://coveralls.io/repos/github/cJarvers/FeedbackNets.jl/badge.svg?branch=master)](https://coveralls.io/github/cJarvers/FeedbackNets.jl?branch=master)
[![](https://img.shields.io/badge/docs-stable-blue.svg)](https://cJarvers.github.io/FeedbackNets.jl/stable)
[![](https://img.shields.io/badge/docs-dev-blue.svg)](https://cJarvers.github.io/FeedbackNets.jl/dev)

## Description

This package implements deep neural networks with feedback. This means that the
output of higher/later layers can serve as an input to lower/earlier layers at
the next timestep.

Most deep learning frameworks do not support this form of recurrence in a
straightforward manner. Usually recurrence is limited to a single layer,
implemented as an RNN cell. This package essentially turns the whole network
into a single RNN cell with support for arbitrary connectivity.

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

The package depends on `Flux` and on `CuArrays` for GPU support. For more
details on Julia package management, look [here](https://julialang.github.io/Pkg.jl/).

## Usage

Once the package is installed, you can access it with Julia's package manager:

```julia
using FeedbackNets
```

Typically, you'll want to load `Flux` as well for its network layers:

```julia
using Flux
```

The core of the package is the `FeedbackChain`, a type that behaves largely
similar to a normal `Flux.Chain`. It treats normal Flux layers as one would
expect. However, it can contain two additional elements: `Splitter`s and
`Merger`s. These two types are used to structure feedback in a network, i.e., to
enable higher levels of the chain to provide input to lower levels in the next
timestep.

A `Splitter` marks a point in the forward stream from which feedback is provided.
As the `FeedbackChain` traverses the feedforward stream, it records the
intermediate output at each `Splitter` and adds it to a state dictionary.

A `Merger` marks a location at which feedback is folded back into the
feedforward stream. Each `Merger` contains the name of the `Splitter` from which
it gets feedback, an operation (e.g., a `ConvTranspose` or a `Chain`) to apply
to the feedback and a binary operation (e.g., `+`) which it applies to combine
forward and feedback input.

For example, a simple `FeedbackChain` may contain a `Dense` layer that maps ten
input units to five outputs and a feedback path that has another `Dense` layer
with the inverse connectivity.

```julia
net = FeedbackChain(
    Merger("fork1", Dense(5, 10, relu), +),
    Dense(10, 5, relu),
    Splitter("fork1")
)
```

At each timestep, this network will take the previous state of `fork1`, pass it
through the 5-to-10 unit `Dense` layer and add it to the 10-unit input. The
result is then passed through the 10-to-5 Dense layer to produce the output of
the network, which is stored for the next timestep by `fork1`.

In order to apply `net` to an input, we need to pass it a dictionary with the
current / inital state of `fork1`.

```julia
x = randn(10)
h = Dict("fork1" => zeros(5))
h, out = net(h, x)
```

A FeedbackChain can be wrapped in a `Flux.Recur` in order to have it handle the
state internally. This requires that an initial state dictionary is provided.

```julia
net = Flux.Recur(net, h)
out = net(x)
```

## License

The project is MIT licensed. See LICENSE for details.
