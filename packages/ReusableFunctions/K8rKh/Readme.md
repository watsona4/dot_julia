ReusableFunctions
=================

[![ReusableFunctions](http://pkg.julialang.org/badges/ReusableFunctions_0.5.svg)](http://pkg.julialang.org/?pkg=ReusableFunctions&ver=0.5)
[![ReusableFunctions](http://pkg.julialang.org/badges/ReusableFunctions_0.6.svg)](http://pkg.julialang.org/?pkg=ReusableFunctions&ver=0.6)
[![ReusableFunctions](http://pkg.julialang.org/badges/ReusableFunctions_0.7.svg)](http://pkg.julialang.org/?pkg=ReusableFunctions&ver=0.7)
[![Build Status](https://travis-ci.org/madsjulia/ReusableFunctions.jl.svg?branch=master)](https://travis-ci.org/madsjulia/ReusableFunctions.jl)
[![Coverage Status](https://coveralls.io/repos/madsjulia/ReusableFunctions.jl/badge.svg?branch=master)](https://coveralls.io/r/madsjulia/ReusableFunctions.jl?branch=master)

Automated storage and retrieval of results for Julia functions calls.
ReusableFunctions is a module of [MADS](http://madsjulia.github.io/Mads.jl).

Installation
-------------

```julia
import Pkg; Pkg.add("ReusableFunctions")
```

Example
---------

```julia
import ReusableFunctions
function f(x)
    @info("function f is executed!")
    sleep(1)
    return x
end
f_reuse = ReusableFunctions.maker3function(f);

julia> f(1) # normal function call
[ Info: function f is executed!
1

# function call using ReusableFunctions function
# the first time f_reuse() is called the original function f() is called
julia> f_reuse(1)
[ Info: function f is executed!
1

# function call using ReusableFunctions function
# the second time f_reuse() is called he original function f() is NOT called
# the already stored output from the first call is reported
julia> f_reuse(1)
1
```

Documentation
-------------

ReusableFunctions functions are documented at [https://madsjulia.github.io/Mads.jl/Modules/ReusableFunctions](https://madsjulia.github.io/Mads.jl/Modules/ReusableFunctions)

Projects using ReusableFunctions
-----------------

* [MADS](https://github.com/madsjulia)
* [TensorDecompositions](https://github.com/TensorDecompositions)

Publications, Presentations, Projects
--------------------------

* [mads.gitlab.io](http://mads.gitlab.io)
* [TensorDecompositions](https://tensordecompositions.github.io)
* [monty.gitlab.io](http://monty.gitlab.io)
* [ees.lanl.gov/monty](https://www.lanl.gov/orgs/ees/staff/monty)