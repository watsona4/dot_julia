export Node

mutable struct Node
    id::String
    hid::Int #attribute by system, not by user
    loc::Vector{Float64}
    T::Matrix{Float64}
    restraints::Vector{Bool}
    spring::Vector{Float64}
    mass::Vector{Float64}
end

function Node(id,hid::Int,x::Float64,y::Float64,z::Float64)
    o=[x,y,z]
    pt1=[x,y,z]+[1,0,0]
    pt2=[x,y,z]+[0,1,0]
    csys=CSys(o,pt1,pt2)
    T=zeros(6,6)
    T[1:3,1:3]=T[4:6,4:6]=csys.T
    restraints=[false,false,false,false,false,false]
    spring=zeros(6)
    mass=zeros(6)
    Node(string(id),hid,o,T,restraints,spring,mass)
end

integrateK(node::Node)=Array(Diagonal((node.T)'*node.spring))
integrateM(node::Node)=Array(Diagonal((node.T)'*node.mass))

# end
