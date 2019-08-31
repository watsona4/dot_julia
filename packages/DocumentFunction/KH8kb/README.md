DocumentFunction
================

A module for documenting Julia functions.
It also provides methods to get function methods, arguments and keywords.

[![DocumentFunction](http://pkg.julialang.org/badges/DocumentFunction_0.5.svg)](http://pkg.julialang.org/?pkg=DocumentFunction&ver=0.5)
[![DocumentFunction](http://pkg.julialang.org/badges/DocumentFunction_0.6.svg)](http://pkg.julialang.org/?pkg=DocumentFunction&ver=0.6)
[![DocumentFunction](http://pkg.julialang.org/badges/DocumentFunction_0.7.svg)](http://pkg.julialang.org/?pkg=DocumentFunction&ver=0.7)
[![Build Status](https://travis-ci.org/madsjulia/DocumentFunction.jl.svg?branch=master)](https://travis-ci.org/madsjulia/DocumentFunction.jl)
[![Coverage Status](https://coveralls.io/repos/madsjulia/DocumentFunction.jl/badge.svg?branch=master)](https://coveralls.io/r/madsjulia/DocumentFunction.jl?branch=master)

DocumentFunction is a module of [MADS](https://github.com/madsjulia) (Model Analysis & Decision Support).

Installation:
------------

```julia
import Pkg; Pkg.add("DocumentFunction")

using DocumentFunction
```

Examples:
------------

``` julia
julia> print(documentfunction(documentfunction))

Methods:
 - `DocumentFunction.documentfunction(f::Function; location, maintext, argtext, keytext) in DocumentFunction` : /Users/monty/.julia/dev/DocumentFunction/src/DocumentFunction.jl:56
Arguments:
 - `f::Function`
Keywords:
 - `argtext`
 - `keytext`
 - `location`
 - `maintext`
```

``` julia
julia> print(documentfunction(occursin))

Methods:
 - `Base.occursin(delim::UInt8, buf::Base.GenericIOBuffer{Array{UInt8,1}}) in Base` : iobuffer.jl:464
 - `Base.occursin(delim::UInt8, buf::Base.GenericIOBuffer) in Base` : iobuffer.jl:470
 - `Base.occursin(needle::Union{AbstractChar, AbstractString}, haystack::AbstractString) in Base` : strings/search.jl:452
 - `Base.occursin(r::Regex, s::SubString; offset) in Base` : regex.jl:172
 - `Base.occursin(r::Regex, s::AbstractString; offset) in Base` : regex.jl:166
 - `Base.occursin(pattern::Tuple, r::Test.LogRecord) in Test` : /Users/osx/buildbot/slave/package_osx64/build/usr/share/julia/stdlib/v1.1/Test/src/logging.jl:211
Arguments:
 - `buf::Base.GenericIOBuffer`
 - `buf::Base.GenericIOBuffer{Array{UInt8,1}}`
 - `delim::UInt8`
 - `haystack::AbstractString`
 - `needle::Union{AbstractChar, AbstractString}`
 - `pattern::Tuple`
 - `r::Regex`
 - `r::Test.LogRecord`
 - `s::AbstractString`
 - `s::SubString`
Keywords:
 - `offset`
```

Documentation Example:
---------

```julia
import DocumentFunction

function foobar(f::Function)
    return nothing
end
function foobar(f::Function, m::Vector{String})
    return nothing
end

@doc """
$(DocumentFunction.documentfunction(foobar;
    location=false,
    maintext="Foobar function to do amazing stuff",
    argtext=Dict("f"=>"Input function ...",
                 "m"=>"Input string array ...")))
""" foobar
```

To get the help for this new function type "?foobar".
This will produces the following output:

```
  foobar

  Foobar function to do amazing stuff

  Methods:

    •    Main.foobar(f::Function) in Main

    •    Main.foobar(f::Function, m::Array{String,1}) in Main

  Arguments:

    •    f::Function : Input function ...

    •    m::Array{String,1} : Input string array ...
```

Projects using DocumentFunction
-----------------

* [MADS](https://github.com/madsjulia) (function documentation is produced using DocumentFunction: [https://madsjulia.github.io/Mads.jl/Modules/Mads](https://madsjulia.github.io/Mads.jl/Modules/Mads))
* [TensorDecompositions](https://github.com/TensorDecompositions)

Publications, Presentations, Projects
----------------

* [mads.gitlab.io](http://mads.gitlab.io)
* [TensorDecompositions](https://tensordecompositions.github.io)
* [monty.gitlab.io](http://monty.gitlab.io)
* [ees.lanl.gov/monty](https://www.lanl.gov/orgs/ees/staff/monty)

