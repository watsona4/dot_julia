
module MolecularTrajectories

export AbstractTrajectory, AbstractFrame
export Trajectory, Frame
export get_num_atoms

using MolecularBoxes

abstract type AbstractFrame{V} end
abstract type AbstractTrajectory{F<:AbstractFrame} end
"""
Holds one frame of a trajectory, including atom positions, 
box dimensions, and time.
"""
struct Frame{V} <: AbstractFrame{V}
    time::Float64
    box::Box{V, 3, (true,true,true)}
    positions::Vector{V}
    velocities::Vector{V}
end

Base.eltype(
    ::Type{<:AbstractTrajectory{F}}
) where F = F

get_num_atoms(f::Frame) = size(f.positions,1)

include("Gromacs.jl")

end
