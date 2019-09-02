# Vector Policy


Tabular policies including the following:

- `VectorPolicy` holds a vector of actions, one for each state, ordered according to state_index.
-  `ValuePolicy` holds a matrix of values for state-action pairs and chooses the action with the highest value at the given state


```@docs
VectorPolicy 
``` 

```@docs
VectorSolver
```

```@docs
ValuePolicy
```