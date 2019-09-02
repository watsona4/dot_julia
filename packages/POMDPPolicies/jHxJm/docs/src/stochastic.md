# Stochastic Policies 

Types for representing randomized policies:

- `StochasticPolicy` samples actions from an arbitrary distribution.
- `UniformRandomPolicy` samples actions uniformly (see `RandomPolicy` for a similar use)
- `CategoricalTabularPolicy` samples actions from a categorical distribution with weights given by a `ValuePolicy`.
- `EpsGreedyPolicy` uses epsilon-greedy action selection.

```@docs
StochasticPolicy
```

```@docs
CategoricalTabularPolicy
```

```@docs
EpsGreedyPolicy
```