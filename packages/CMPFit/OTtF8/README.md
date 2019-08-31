# CMPFit
## A Julia wrapper for the `mpfit` library (MINPACK minimization).

[![Build Status](https://travis-ci.org/gcalderone/CMPFit.jl.svg?branch=master)](https://travis-ci.org/gcalderone/CMPFit.jl)

The `CMPFit.jl` package is a wrapper for the [`mpfit` C-library](https://www.physics.wisc.edu/~craigm/idl/cmpfit.html) by Craig Markwardt, providing access to the the [MINPACK](http://www.netlib.org/minpack/) implementation of the
[Levenberg-Marquardt algorithm](https://en.wikipedia.org/wiki/Levenberg%E2%80%93Marquardt_algorithm), and allowing simple and quick solutions to Least Squares minimization problems in Julia.

**This is a wrapper for a C library, hence it require to download the C code and compile it.**
Check the [LsqFit](https://github.com/JuliaNLSolvers/LsqFit.jl) package for a pure Julia solution.

-------

## Installation

To install `CMPFit` your machine should be equipped with `CMake` and a C compiler.  In the Julia REPL type:

``` julia
] add CMPFit
```
This will automaticaly download the `cmpfit` library (v1.3) from [Craig's webpage](https://www.physics.wisc.edu/~craigm/idl/cmpfit.html) and compile it.


-------

## Usage

Usage is very simple: given a set of observed data and uncertainties, define a (whatever complex) Julia function to evaluate a model to be compared with the data, and ask `cmpfit` to find the model parameter values which best fit the data.

Example:

``` julia
using CMPFit

# Independent variable
x = [-1.7237128E+00,1.8712276E+00,-9.6608055E-01,
    -2.8394297E-01,1.3416969E+00,1.3757038E+00,
    -1.3703436E+00,4.2581975E-02,-1.4970151E-01,
    8.2065094E-01]

# Observed data
y = [-4.4494256E-02,8.7324673E-01,7.4443483E-01,
     4.7631559E+00,1.7187297E-01,1.1639182E-01,
     1.5646480E+00,5.2322268E+00,4.2543168E+00,
     6.2792623E-01]

# Data uncertainties
e = fill(0., size(y)) .+ 0.5

# Define a model (actually a Gaussian curve)
function GaussModel(x::Vector{Float64}, p::Vector{Float64})
  sig2 = p[4] * p[4]
  xc = @. x - p[3]
  model = @. p[2] * exp(-0.5 * xc * xc / sig2) + p[1]
  return model
end

# Guess model parameters
param = [0.0, 1.0, 1.0, 1.0]

# Call `cmpfit` and print the results:
res = cmpfit(x, y, e, GaussModel, param);
println(res)
```

The value returned by `cmpfit` is a Julia structure.  You may look at its content with:
``` julia
dump(res)
```

Specifically, the best fit parameter values and their 1-sigma uncertainties are:
``` Julia
println(res.param)
println(res.perror)
```

`CMPFit` mirrors all the facilities provided by the underlying C-library, e.g. a parameter can be fixed during the fit, or its value limited to a specific range. Moreover, the whole fitting process may be customized for, e.g., limiting the maximum number of model evaluation, or change the relative chi-squared convergence criterium. E.g.:
``` Julia
# Set guess parameters
param = [0.5, 4.5, 1.0, 1.0]

# Create the `parinfo` structures for the 4 parameters used in the 
# example above:
pinfo = CMPFit.Parinfo(4)

# Fix the value of the 1st parameter:
pinfo[1].fixed = 1

# Set a lower (4) and upper limit (5) for the 2nd parameter
pinfo[2].limited = (1,1)
pinfo[2].limits = (4, 5)

# Create a `config` structure
config = CMPFit.Config()

# Limit the maximum function evaluation to 200
config.maxfev = 200

# Change the chi-squared convergence criterium:
config.ftol = 1.e-5

# Re-run the minimization process
res = cmpfit(x, y, e, GaussModel, param, parinfo=pinfo, config=config);
println(res)
```

See [Craig's webpage](https://www.physics.wisc.edu/~craigm/idl/cmpfit.html) for further documentation on the `config` and `parinfo` structures.

