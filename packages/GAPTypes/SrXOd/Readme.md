# GAPTypes.jl

This module provides the abstract Julia type `GapObj`,
which is used in GAP.jl to give the concrete internal
GAP type `MPtr` an abstract type that it is derived from.

If you want to use GAP.jl, please use this package
and the `GapObj` type to define functions and structs
that contain pure GAP objects.