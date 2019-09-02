# PhaseSpaceIO

[![Build Status](https://travis-ci.org/jw3126/PhaseSpaceIO.jl.svg?branch=master)](https://travis-ci.org/jw3126/PhaseSpaceIO.jl)
[![codecov.io](https://codecov.io/github/jw3126/PhaseSpaceIO.jl/coverage.svg?branch=master)](http://codecov.io/github/jw3126/PhaseSpaceIO.jl?branch=master)

## Usage

```julia
julia> using PhaseSpaceIO

julia> path = joinpath(dirname(pathof(PhaseSpaceIO)), "..", "test", "assets","some_file.IAEAphsp");

julia> ps = iaea_iterator(collect,path)
1-element Array{Particle{0,1},1}:
 Particle(typ=photon, E=1.0, weight=2.0, x=3.0, y=4.0, z=5.0, u=0.53259337, v=0.3302265, w=-0.7792912, new_history=true, extra_floats=(), extra_ints=(13,))

julia> dir = mkpath(tempname())
"/tmp/julia7uigbI"

julia> readdir(dir)
0-element Array{String,1}

julia> path = joinpath(dir, "hello")
"/tmp/julia7uigbI/hello"

julia> iaea_writer(path, RecordContents{0,1}()) do w
           for p in ps
               write(w,p)
           end
       end

julia> readdir(dir)
2-element Array{String,1}:
 "hello.IAEAheader"
 "hello.IAEAphsp"  
```
