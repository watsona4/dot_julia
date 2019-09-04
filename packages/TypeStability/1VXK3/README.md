# TypeStability.jl

[![Build Status](https://travis-ci.org/Collegeville/TypeStability.jl.svg?branch=master)](https://travis-ci.org/Collegeville/TypeStability.jl) [![Stable Docs](https://img.shields.io/badge/docs-stable-blue.svg)](https://Collegeville.github.io/TypeStability.jl/stable/) [![Latest Docs](https://img.shields.io/badge/docs-latest-blue.svg)](https://Collegeville.github.io/TypeStability.jl/latest/) [![Version](https://img.shields.io/github/release/Collegeville/TypeStability.jl.svg)](https://github.com/Collegeville/TypeStability.jl/releases)

This package provides functions to automate checking functions for type stability.  The checks are only run when enabled, which allows the function signatures that need to perform well to be located with the actual code without hurting runtime performance.

TypeStability.jl is tested on Julia versions 0.6 through 1.1.

### License

TypeStability.jl is licensed under the MIT "Expat" license.  See [LICENSE.md](LICENSE.md) for more information.

### Setup

Run `Pkg.add(TypeStability)` to install the latest stable version of TypeStability.  Then TypeStability can be `using`ed or `import`ed.

### Example

Documentation is located at [https://collegeville.github.io/TypeStability.jl/stable/](https://collegeville.github.io/TypeStability.jl/stable/) or, for the latest version, [https://collegeville.github.io/TypeStability.jl/latest/](https://collegeville.github.io/TypeStability.jl/latest/)

The function `enable_inline_stability_checks(::Bool)` enables running the stability checks, while the macro `@stablefunction(signatures, function)` handles running the checks.

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

### Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for instructions on contrinbuting to TypeStability.jl.
