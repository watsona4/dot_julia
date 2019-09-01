# Abstract Base Types

## AbstractFeedbackNet

`AbstractFeedbackNet` is the base type for networks that can handle feedback
connections.

```@docs
AbstractFeedbackNet
```

Every type that inherits from `AbstractFeedbackNet` should support iteration
over its layers. This is used to implement the `splitnames` and `namesvalid`
functions in a generic manner.

```@docs
splitnames(net::AbstractFeedbackNet)
```

```@docs
namesvalid(net::AbstractFeedbackNet)
```

## AbstractMerger

`AbstractMerger` is the base type for layers that merge several streams (e.g.,
feedforward and feedback). Any type that inherits from it should implement a
function to apply an instance of it to an input and a state dictionary from
which to get the feedback streams.

```@docs
AbstractMerger
```
