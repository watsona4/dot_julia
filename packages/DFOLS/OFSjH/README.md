# DFOLS

[![Build Status](https://travis-ci.com/QuantEcon/DFOLS.jl.svg?branch=master)](https://travis-ci.com/QuantEcon/DFOLS.jl)

A light wrapper around the [DFO-LS](https://numericalalgorithmsgroup.github.io/dfols) (Derivative-Free Optimizer for Least-Squares Minimization) Python package written by the Numerical Algorithms Group at Oxford University. See here for [the paper](https://arxiv.org/abs/1804.00154) and the [github repository](https://github.com/numericalalgorithmsgroup/dfols).

### TOC

1. Installation
2. Usage
3. Constraints and Stochastic Objectives
4. Advanced Usage

**Note:** This package is GPL3 licensed, to comply with the underlying Python.

### Installation

Simply run

```
] add DFOLS
```

**Note:** The build script assumes that `$(PyCall.pyprogramname) pip` is a valid command. This is automatically true on Windows and macOS, but needs to be verified on Linux (i.e., make sure it isn't `pip3`, or `python-pip3`, or something). You can do this by aliasing `pip=pip3` or setting up a symbolic link `pip -> pip3`.

### Usage

We define a type `DFOLSResults` to store the solver output.

```
struct DFOLSResults{TI, TF}
    x::Array{TF, 1}
    resid::Array{TF, 1}
    f::TF
    jacobian::Union{Nothing, Matrix{TF}} # jacobian is nothing if convergence is immediate
    nf::TI
    nx::TI # differs from nf if sample averaging is used
    nruns::TI # > 1 if multiple restarts
    flag::TI
    msg::String
    EXIT_SUCCESS::TI
    EXIT_MAXFUN_WARNING::TI
    EXIT_SLOW_WARNING::TI
    EXIT_FALSE_SUCCESS_WARNING::TI
    EXIT_INPUT_ERROR::TI
    EXIT_TR_INCREASE_ERROR::TI
    EXIT_LINALG_ERROR::TI
end
```

And we define a set of convenience functions to interact with it

```
converged, optimizer, optimum, residuals, jacobian, nf, nruns, nx, flag, msg
```

You can run the solver by calling the `solve` function, as below

```
rosenbrock = x -> [10. * (x[2]-x[1]^2), 1. - x[1]]
sol = solve(rosenbrock, [-1.2, 1.])
```

Options for `solve` include

```
function solve(objfun, x0::Array{TF, 1};
                bounds = nothing,
                npt = nothing,
                rhobeg = nothing,
                rhoend = 1e-8,
                maxfun = nothing,
                nsamples = nothing,
                user_params = nothing, # see https://numericalalgorithmsgroup.github.io/dfols/build/html/advanced.html
                objfun_has_noise = false,
                scaling_within_bounds = false) where {TF <: AbstractFloat}
```

### Constraints and Stochastic Objectives

You can impose constraints on the solution space

```
solve(rosenbrock, x0, bounds = ([-5., -5.], [5., 5.])) # two-sided box
solve(rosenbrock, x0, bounds = ([-5., -5.], nothing)) # one-sided constraint
```

And note that the objective is stochastic

```
σ = 0.01
μ = 1.
rosenbrock_noisy = x -> rosenbrock(x) .* (μ .+ σ*randn(2))
solve(rosenbrock_noisy, x0, objfun_has_noise=true)
```

**Note:** The solver will determine the stochasticity of the objective only by examining the `objfun_has_noise` flag, and not by looking at the actual function supplied.

### Advanced Usage

The `user_params` should be a Julia dict (see [here](https://numericalalgorithmsgroup.github.io/dfols/build/html/advanced.html) for valid key, value pairs). For example:

```
solve(rosenbrock, x0, user_params = Dict("init.random_initial_directions" => false,
                                        "model.abs_tol" => 1e-20,
                                        "noise.quit_on_noise_level" => false))
```
