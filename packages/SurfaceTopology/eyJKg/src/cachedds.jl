"""
A datastructure which in addition to a list of faces stores connectivity information for each vertex.
"""
struct CachedDS
    faces
    connectivity
end

Faces(t::CachedDS) = t.faces
Edges(t::CachedDS) = filter(x->x[1]<x[2],decompose(Face{2,Int},t.faces)) 

"""
    CacheDS(t)

Constructs cached face based datastructure `CachedDS` from arbitrary topology `t` which provides `EdgeRing` iterator. 
"""
function CachedDS(faces)
    vmax = maximum(maximum(faces))
    connectivity = Array{Int,1}[]
    for i in 1:vmax
        v1 = Array{Int}(undef,0)
        v2 = Array{Int}(undef,0)
        for (v1i,v2i) in EdgeRing(i,faces)
            push!(v1,v1i)
            push!(v2,v2i)
        end
        
        vj = v2[1]
        coni = [vj]
        for j in 2:length(v1)
            vj, = v2[v1.==vj]
            push!(coni,vj)
        end
        push!(connectivity,coni)
    end
    return CachedDS(faces,connectivity)
end

VertexRing(vi::Int64,t::CachedDS) = t.connectivity[vi]
EdgeRing(vi::Int64,t::CachedDS) = PairIterator(t.connectivity[vi]) 
FaceRing(vi::Int64,t::CachedDS) = error("Face ring is not suitable for this datastructure.")
