module FEStructure
using SparseArrays
using LinearAlgebra

using HCubature

using ..FESparse
using ..Enums
using ..CoordinateSystem
include("./FEMaterial.jl")
include("./FESection.jl")
include("./FENode.jl")
abstract type AbstractElement end
include("./FEBeam.jl")
include("./FEQuad.jl")
include("./FETria.jl")
#
# using .FEMaterial,.FESection
# using .FENode, .FEBeam, .FEQuad, .FETria

export Structure,AbstractElement,
add_uniaxial_metal!,add_section!,add_general_section!,add_beam_section!,
add_node!,set_nodal_restraint!,set_nodal_spring!,set_nodal_mass!,
add_beam!,set_beam_release!,set_beam_orient!,
add_quad!,set_quad_rotation!,
add_tria!,set_tria_rotation!,

set_damp_constant!,set_damp_Rayleigh!,
integrateK,integrateM,integrateP,
integrateKσ

mutable struct Structure
    csyses::Dict{String,CSys}

    materials::Dict{String,Material}
    sections::Dict{String,BeamSection}

    nodes::Dict{String,Node}
    links::Array
    cables::Array
    beams::Dict{String,Beam}
    quads::Dict{String,Quad}
    trias::Dict{String,Tria}

    damp::String
    ζ₁::Float64
    ζ₂::Float64

    K::SparseMatrixCSC
    K̄::SparseMatrixCSC
    M::SparseMatrixCSC
    M̄::SparseMatrixCSC
    C::SparseMatrixCSC
    C̄::SparseMatrixCSC
end

function Structure()
    globalcsys=CSys([0.,0.,0.],[1.,0.,0.],[0.,1.,0.])
    K=spzeros(1,1)
    K̄=spzeros(1,1)
    M=spzeros(1,1)
    M̄=spzeros(1,1)
    C=spzeros(1,1)
    C̄=spzeros(1,1)
    Structure(Dict("Global"=>globalcsys),Dict{String,Material}(),Dict{String,BeamSection}(),Dict{String,Node}(),[],[],
    Dict{String,Beam}(),Dict{String,Quad}(),Dict{String,Tria}(),"constant",0.05,0,K,K̄,M,M̄,C,C̄)
end

include("./interface.jl")
end
