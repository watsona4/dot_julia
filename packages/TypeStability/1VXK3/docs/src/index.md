# TypeStability.jl

```@contents
```

TypeStability.jl provides tools to automatically check the type stability of functions.

## Inline Stability Checks

TypeStability.jl provides the ability to inline the checks with the function declarations.

The inline checks are disable by default, but are enabled with the function `enable_inline_stability_checks(::Bool)`.  This allows the checks to not reduce the load time of the functions, unless the type stability checks are explictly requested such as while unit testing.

A basic example of using inline checks:
```julia
julia> using TypeStability

julia> enable_inline_stability_checks(true)
true

julia> @stable_function [(Float64,)] function f(x)
                          if x > 0
                              x
                          else
                              Int(0)
                          end
                      end
f(Float64) is not stable
  return is of type Union{Float64, Int64}

julia> f
f (generic function with 1 method)

julia> @stable_function [(Float64,)] function g(x)
                          if x > 0
                              x
                          else
                             0.0
                          end
                      end

julia> g
g (generic function with 1 method)
```

The `@stable_function` macro has 2 signatures, `@stable_function(signatures, function)` and `@stable_function(signatures, accepted_instability, function)`.  The `signatures` argument is a iterable collection of method signatures to test for stability, where each method signature is a tuple of types or an `AbstractArray` of types.  The `accepted_instability` argument is a `Dict`-like object with a `get` method, see `check_method` for details.  Finally, `function` is either a symbol naming the function to test, or an Expr containing one or more function definitions.  Multiple functions can be nesting in a `block` Expr and macros are expanded before walking the code, but functions nested in structures may not be recognized.  If `inline_stability_checks_enabled` returns true, each function is checked for stability as per `check_function`, then prints warnings if there are any instabilities found.


## External Stability Checks

Stability can also be checked in a seperate location from the function declarations.  The functions `check_function` and `check_method` check the stability of a list of methods or just one method respectively and provide `StabilityReport` objects containing the results.   The functions `check_function` and `check_method` take an optional argument of `accepted_instability`, which is an object that should have a `get` method (like `Dict`) that acts as a whitelist of unstable variables.

Stability reports can be inspected with the functions `is_stable` and `stability_warn`.  `is_stable` takes either a single `StabilityReport`, an `AbstractArray{StabilityReport}` or a `Set{StabilityReport}` object and returns true if all of the reports have no instability.  The `stability_warn` function takes the name of a function and a iterable collection of method signature - stability report pairs and displays a warning message for any instability.
