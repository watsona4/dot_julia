# MolecularTrajectories.jl

[![Build Status](https://travis-ci.org/tom--lee/MolecularTrajectories.jl.svg?branch=master)](https://travis-ci.org/tom--lee/MolecularTrajectories.jl)
[![Coverage Status](https://coveralls.io/repos/tom--lee/MolecularTrajectories.jl/badge.svg?branch=master)](https://coveralls.io/r/tom--lee/MolecularTrajectories.jl?branch=master)

A Julia package for reading and writing molecular dynamics simulation 
trajectories.

Currently supports iteration over a series of GROMACS-format `.gro` files and 
writing of a single trajectory frame as a `.gro` file.

GROMACS-format `.xtc` files will be supported in a future release.

## Usage

```julia
julia> using MolecularTrajectories

julia> using StaticArrays

julia> const Vec = SVector{3, Float64}

julia> gro_path = joinpath(dirname(pathof(MolecularTrajectories)), "../test/test.gro")

julia> gro_paths = [gro_path, gro_path]

julia> trajectory = GroTrajectory{Vec}(gro_paths, dt=1.0)

julia> for frame in trajectory
    @show frame.time
    @show frame.box
    @show frame.positions[1:10]
    @show frame.velocities[1:10]
end

julia> using MolecularTopologies

julia> topology = open(gro_topology, gro_path)

julia> frame = first(GroTrajectory{Vec}(gro_paths, dt=1.0))

julia> open("output.gro", "w") do g
    write_frame(g, GroTrajectory, frame, topology, "Some gro file")
end

```

Note that trajectory objects are iterable but not indexable;
they do not support the `AbstractArray` interface.

