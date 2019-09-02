module Load

using LinearAlgebra
using SparseArrays
using HCubature

export NodalForce,NodalDisp,
BeamForce,QuadForce

abstract type AbstractElementForce end

struct NodalForce
    id::String
    val::Vector{Float64}
    csys::String #This is a string to indicate whether the value is given in global or local csys.
    NodalForce(id,force,csys="global")=new(id,force,csys)
end

struct NodalDisp
    id::String
    val::Vector{Float64}
    csys::String
    NodalDisp(id,disp,csys="global")=new(id,disp,csys)
end

mutable struct BeamForce  <: AbstractElementForce
    id::String
    f::Vector{Float64}
    s::Vector{Float64}
    σ₀::Vector{Float64}
    ϵ₀::Vector{Float64}
    BeamForce(id)=new(id,zeros(12),zeros(12),zeros(2),zeros(2))
end

mutable struct QuadForce  <: AbstractElementForce
    id::String
    f::Vector{Float64}
    s::Vector{Float64}
    σ₀::Vector{Float64}
    ϵ₀::Vector{Float64}
    QuadForce(id)=new(id,zeros(24,1),zeros(24,1),zeros(4,1),zeros(4,1))
end

end
