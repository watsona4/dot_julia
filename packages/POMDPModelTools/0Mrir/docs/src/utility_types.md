# Utility Types

## Terminal State

`TerminalState` and its singleton instance `terminalstate` are available to use for a terminal state in concert with another state type. It has the appropriate type promotion logic to make its use with other types friendly, similar to `nothing` and `missing`.

!!! note

    NOTE: This is NOT a replacement for the standard POMDPs.jl isterminal function, though isterminal is implemented for the type. It is merely a convenient type to use for terminal states.

!!! warning
    
    WARNING: Early tests (August 2018) suggest that the Julia 1.0 compiler will not be able to efficiently implement union splitting in cases as  complex as POMDPs, so using a `Union` for the state type of a problem can currently have a large overhead.


```@docs
TerminalState
terminalstate
```
