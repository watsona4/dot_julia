module JointType

using LinearAlgebra

export ChooseJoint

mutable struct ChooseJoint
    nudof::Int
    ncdof::Int
    udof::Vector{Int}
    cdof::Union{Vector{Int},Nothing}
    S::Union{Vector{Int},Matrix{Int}}
    T::Union{Vector{Int},Matrix{Int},Nothing}
end

function ChooseJoint(kind)

    if kind == "revolute"
        nudof = 1
        ncdof = 5
        udof = [3]
        cdof = [1, 2, 4, 5, 6]
        S = Matrix{Int}(I,6,6)[:,udof]
        T = Matrix{Int}(I,6,6)[:,cdof]

    elseif kind == "prismatic"
        nudof = 1
        ncdof = 5
        udof = [6]
        cdof = [1, 2, 3, 4, 5]
        S = Matrix{Int}(I,6,6)[:,udof]
        T = Matrix{Int}(I,6,6)[:,cdof]

    elseif kind == "cylindrical"
        nudof = 2
        ncdof = 4
        udof = [3, 6]
        cdof = [1, 2, 4, 5]
        S = Matrix{Int}(I,6,6)[:,udof]
        T = Matrix{Int}(I,6,6)[:,cdof]

    elseif kind == "planar"
        nudof = 3
        ncdof = 3
        udof = [3, 4, 5]
        cdof = [1, 2, 6]
        S = Matrix{Int}(I,6,6)[:,udof]
        T = Matrix{Int}(I,6,6)[:,cdof]

    elseif kind == "spherical"
        nudof = 3
        ncdof = 3
        udof = [1, 2, 3]
        cdof = [4, 5, 6]
        S = Matrix{Int}(I,6,6)[:,udof]
        T = Matrix{Int}(I,6,6)[:,cdof]

    elseif kind == "custom_prismatic_in_z"
        # custom joints only allow a maximum of 2 dofs
        nudof = 1
        ncdof = 5
        udof = [6]
        cdof = [1, 2, 3, 4, 5]
        S = Matrix{Int}(I,6,6)[:,udof]
        T = Matrix{Int}(I,6,6)[:,cdof]

    elseif kind == "custom_prismatic_in_y"
        nudof = 1
        ncdof = 5
        udof = [5]
        cdof = [1, 2, 3, 4, 6]
        S = Matrix{Int}(I,6,6)[:,udof]
        T = Matrix{Int}(I,6,6)[:,cdof]

    elseif kind == "free"
        nudof = 6
        ncdof = 0
        udof = [1, 2, 3, 4, 5, 6]
        cdof = nothing
        S = Matrix{Int}(I,6,6)[:,udof]
        T = nothing
    else
        error("Joint type not supported in JointType.jl")
    end

    return ChooseJoint(nudof, ncdof, udof, cdof, S, T)
end



end
