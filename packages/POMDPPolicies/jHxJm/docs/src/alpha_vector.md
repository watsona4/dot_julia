# Alpha Vector Policy

Represents a policy with a set of alpha vectors (See `AlphaVectorPolicy` constructor docstring). In addition to finding the optimal action with `action`, the alpha vectors can be accessed with [`alphavectors`](@ref) or [`alphapairs`](@ref).

Determining the estimated value and optimal action depends on calculating the dot product between alpha vectors and a belief vector. [`POMDPPolicies.beliefvec(pomdp, b)`](@ref) is used to create this vector and can be overridden for new belief types for efficiency.


```@docs
AlphaVectorPolicy
alphavectors
alphapairs
POMDPPolicies.beliefvec
``` 
