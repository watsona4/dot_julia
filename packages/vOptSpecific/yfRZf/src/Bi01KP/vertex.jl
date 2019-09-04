# MIT License
# Copyright (c) 2017: Xavier Gandibleux, Anthony Przybylski, Gauthier Soleilhac, and contributors.
mutable struct vertex
    layer::Int #index of the layer in the graph
    i::Int  #index of the variable
    w::Int  #accumulated weight
    zλ::Int #best profit possible for zλ
    z1::Int #best profit possible for z1
    z2::Int #best profit possible for z2
    has_parent_0::Bool
    has_parent_1::Bool
    parent_0::vertex #parent node, with an edge having a profit == 0
    parent_1::vertex #parent node, with an edge having a profit > 0
    vertex(l,i,w,zλ,z1,z2,hp0,hp1) = new(l,i,w,zλ,z1,z2,hp0,hp1)
    vertex(l,i,w,zλ,z1,z2,hp0,hp1,p) = new(l,i,w,zλ,z1,z2,hp0,hp1,p,p)
end

# Base.show(io::IO, v::vertex) = print(io, "v_",v.i,"_",v.w,"(",v.zλ,")(",v.layer,")")
Base.show(io::IO, v::vertex) = print(io, "v_",v.i,"_",v.w,"(",v.z1,",",v.z2,")(",v.layer,")")

#v_i_0
source(mono_pb::mono_problem) = vertex(1,mono_pb.variables[1],mono_pb.ω,mono_pb.min_profit_λ,mono_pb.min_profit_1,mono_pb.min_profit_2,false,false)

#inner degree of a vertex
inner_degree(v::vertex) = v.has_parent_0 + v.has_parent_1

#Creates a vertex v_i+1_w from a vertex v_i_w assuming we decided not to pick item i
function vertex_skip(v::vertex, mono_pb::mono_problem)
    varplus1 = v.layer == size(mono_pb) ? v.layer + 1 : mono_pb.variables[v.layer+1]
    return vertex(v.layer+1, varplus1, v.w, v.zλ, v.z1, v.z2, true, false, v)
end

#Creates a vertex v_i+1_w' from a vertex v_i_w assuming we decided to pick item i
function vertex_keep(v::vertex, mono_pb::mono_problem)
    #@assert v.mono_pb.variables[v.layer] == v.i
    var = v.i
    varplus1 = v.layer == size(mono_pb) ? v.layer + 1 : mono_pb.variables[v.layer+1]
    return vertex(v.layer+1,
            varplus1,
            v.w+mono_pb.w[var],
            v.zλ+mono_pb.p[var],
            v.z1+mono_pb.p1[var],
            v.z2+mono_pb.p2[var],
            false, true,
            v)
end

#merge two vertices
function merge!(a::vertex, b::vertex)
    if b.zλ >= a.zλ
        a.zλ, a.z1, a.z2 = b.zλ, b.z1, b.z2
    end
    a.has_parent_1 = true
    a.parent_1 = b.parent_1
end

#Comparison functions for searchsorted()
weight_lt(v::vertex, w::Int) = v.w < w
weight_lt(w::Int, v::vertex) = w < v.w

#Returns the unique parent of a vertex
function parent(v::vertex)
    return v.has_parent_0 ? v.parent_0 : v.parent_1
end

#Returns both parents of a vertex
function parents(v::vertex)
    return v.parent_0, v.parent_1
end

zλ(v::vertex) = v.zλ
z1(v::vertex) = v.z1
z2(v::vertex) = v.z2