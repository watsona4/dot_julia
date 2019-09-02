LCIO bindings for Julia
=======================
Build Status: [![Build Status](https://travis-ci.com/jstrube/LCIO.jl.svg?branch=master)](https://travis-ci.com/jstrube/LCIO.jl)
Documentation Status: [![Documentation Status](https://readthedocs.org/projects/lciojl/badge/?version=latest)](https://lciojl.readthedocs.io/en/latest/?badge=latest)


Introduction
------------
This is a package for reading the LCIO file format, used for studies of the International Linear Collider, and other future collider concepts. See http://lcio.desy.de for details.

Prerequisites
-------------
 - The julia programming language: http://julialang.org/
 - A compiler that accepts the --std=c++-14 flag. Set the CXX and CC environment variables if this is different from your default compiler.
LCIO will be built from source to reduce problems with version incompatibilities.


Installation Instructions
-------------------------
Make sure that the `julia` executable is in your `$PATH` environment variable, or your `$JULIA_HOME` variable is set to the directory that contains the `julia` executable. 
```
bash
julia -e 'Pkg.add("LCIO")'
```

If you want to get the latest version (which might have newer features (and bugs) than the latest release), you can run
```
Pkg.checkout("LCIO")
Pkg.build("LCIO")
```
from the julia prompt; after the `Pkg.add` command.


Philosophy
----------
We have attempted to achieve a faithful translation of the C++ API, with method names equal to those documented on the LCIO pages. Nevertheless, attempts have been made to improve the user experience.
Examples:
 - All collections are typed, no casting necessary
 - Methods that return a `float*` or `double*` in the C++ API return a `float64[]` instead.
 - Many of the methods on the C++ side returning pointers can return `nullptr`, so need to be wrapped in `if` clauses. The way to deal with this on the julia side is to use something like the following syntax:

 ```
 ok, value = getReferencePoint(particle)
 if ok
     println(value)
end
```
 - A notable exception is `getPosition` for hits, and `getMomentum` for particles, which we assume always return valid values

Getting Started
---------------
The basic construct for iterating over a file is this:
```
using LCIO
LCIO.open("file.slcio") do reader
    for event in reader
        println(getEventNumber(event))
    end
end
```
There are more examples in the `examples/` directory.

Troubleshooting
---------------
There are currently a couple of hiccups in the dependencies. Work to simplify the installation process is on-going, but in the meantime:
Ubuntu 17.10:
 - Install zlib, cmake, g++-7 through the package manager
 - Download Julia from the julialang.org homepage
 - Set the PATH variable such that you find the julia executable
 - start julia
 ```Pkg.add("CxxWrap")
 Pkg.checkout("CxxWrap")
 Pkg.add("LCIO")
 Pkg.test("LCIO")
 ```
If that doesn't work, please complain through the issues. I have not tested this on other systems recently.
