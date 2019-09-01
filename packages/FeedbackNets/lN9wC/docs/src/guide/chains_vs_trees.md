# Controlling Information Flow: Chains vs Trees

FeedbackNets.jl provides two types to implement deep networks with feedback:
`FeedbackChain`s and `FeedbackTree`s. Their interfaces are identical and they
can be used interchangably. The difference between the two is how information
flows through the network in the forward pass. Whereas a `FeedbackChain`
propagates information from input to output in a single timestep, a `FeedbackTree`
breaks this up over several timesteps.

## FeedbackChains: Fast Forward Passing

`FeedbackChain`s behave in a way that should be intuitive to users of pure
feedforward networks: in each timestep, all layers are applied sequentially to
transform input into output. There is feedback across timesteps via `Splitter`s
and `Merger`s, but this does not change the fact that the network can be
conceptualized as a **sequence** of layers.

However, this means that there is a fundamental asymmetry between information
passed in the forward and the backward direction. Imagine a model of ten layers,
each of which provides feedback to the previous one. A change in the input will
propagate forward to the final layer within one timestep. However, in order for
feedback from the top layer to affect what happens in the lowest layer of the
network, it has to propagate to layer 9 (which takes one timestep), then to
layer 8 (another timestep) and so on. It will take 9 timesteps to reach the
first layer.

This asymmetry is abolished in `FeedbackTree`s

## FeedbackTrees: Symmetric Passing

In a feedback tree, layers are applied to the input in sequence until the first
`Splitter` is encountered. As in a `FeedbackChain`, the current value is saved
to the state dictionary. However, the network then retrieves the value stored at
the previous timestep and applies the next layers to that. In the ten-layer
network scenario outlined above, this means that ten timesteps are necessary for
a new input to affect the output layer. Information spreads with the same speed
in the forward and backward direction.
