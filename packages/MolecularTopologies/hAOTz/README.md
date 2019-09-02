# MolecularTopologies.jl

[![Build Status](https://travis-ci.org/tom--lee/MolecularTopologies.jl.svg?branch=master)](https://travis-ci.org/tom--lee/MolecularTopologies.jl)
[![Coverage Status](https://coveralls.io/repos/tom--lee/MolecularTopologies.jl/badge.svg?branch=master)](https://coveralls.io/r/tom--lee/MolecularTopologies.jl?branch=master)

A Julia package for representing system topologies for molecular simulations.

The package currently only supporting reading atom names, residues names, and
residue indices from a GROMACS-format `.gro` file. Other formats may be 
supported in the future.

## Basic Usage

```julia
julia> using MolecularTopologies

julia> gro_path = joinpath(dirname(pathof(MolecularTopologies)), "../test/test.gro")
"/some/directories/MolecularTopologies.jl/src/../test/test.gro"

julia> topology = open(gro_topology, gro_path)
GroTopology(["CG1", "CG2", "CG3", "N", "CB", "CA", "OA", "P", "OP1", "OP2"  …  "HW2", "OW", "HW1", "HW2", "OW", "HW1", "HW2", "OW", "HW1", "HW2"], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1  …  17141, 17142, 17142, 17142, 17143, 17143, 17143, 17144, 17144, 17144], ["DLPC", "DLPC", "DLPC", "DLPC", "DLPC", "DLPC", "DLPC", "DLPC", "DLPC", "DLPC"  …  "SOL", "SOL", "SOL", "SOL", "SOL", "SOL", "SOL", "SOL", "SOL", "SOL"])

julia> topology.atom_names[60]
"C2C"

julia> topology.residue_names[60]
"DLPC"

julia> topology.residue_indices[60]
2

julia> topology.atom_names[topology.residue_indices .== 10000]
3-element Array{String,1}:
 "OW"
 "HW1"
 "HW2"
```


