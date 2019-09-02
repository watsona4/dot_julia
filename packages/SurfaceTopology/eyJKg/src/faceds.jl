"""
A face based datastructure storing faces, neighbour face indices and vertex to face map arrays. 
"""
struct FaceDS
    faces::Array{Face{3,Int},1}
    neighs::Array{Face{3,Int},1}
    vfaces::Array{Int,1}
end

Faces(t::FaceDS) = t.faces
Edges(t::FaceDS) = filter(x->x[1]<x[2],decompose(Face{2,Int},t.faces))

"""
    FaceDS(faces::PlainDS)

Constructs a face based datastructure from PlainDS. Returns a struct FaceDS with original faces, computed neighbour faces and vertex to face map (one face for each vertex).  
"""
function FaceDS(faces::PlainDS)

    vfaces = Array{Int}(undef,maximum(maximum(faces)))
    neighs = Array{Face{3,Int},1}(undef,length(faces))
    
    for vi in 1:maximum(maximum(faces))
        vfaces[vi] = find_triangle_vertex(vi,faces)
    end

    for ti in 1:length(faces)
        v1, v2, v3 = faces[ti]
        t1 = find_other_triangle_edge(v2,v3,ti,faces)
        t2 = find_other_triangle_edge(v1,v3,ti,faces)
        t3 = find_other_triangle_edge(v1,v2,ti,faces)
        neighs[ti] = Face(t1,t2,t3)
    end
    
    return FaceDS(faces,neighs,vfaces)
end

function start(iter::FaceRing{FaceDS})
    vface = iter.t.vfaces[iter.v]
    i0 = 1
    return (i0,vface)
end

function done(iter::FaceRing{FaceDS},state::Tuple{Int,Int})
    i, face = state
    i0, vface = start(iter)
    if !(i==i0) & (face==vface)
        return true
    else
        return false
    end    
end

function next(iter::FaceRing{FaceDS},state::Tuple{Int,Int})

    i, tri = state
    v = iter.v
    face = iter.t.faces[tri]
    neighbours = iter.t.neighs[tri]

    index = face.==v
    w = index[[1,2,3]]
    cw = index[[3,1,2]]

    nexttri, = neighbours[cw]

    if nexttri==-1
        error("The surface is not closed")
    end
    
    return tri, (i+1,nexttri)
end


Base.iterate(iter::FaceRing{FaceDS}) = next(iter,start(iter))
function Base.iterate(iter::FaceRing{FaceDS},ti)
    if done(iter,ti)
        return nothing
    else
        return next(iter,ti)
    end
end

VertexRing(v::Int,t::FaceDS) = VertexRing(v,t.vfaces[v],t)


function done(iter::VertexRing{FaceDS},state::Tuple{Int,Int})
    i, face = state
    if !(i==1) & (face==iter.t.vfaces[iter.v]) 
        return true
    else
        return false
    end    
end

function next(iter::VertexRing{FaceDS},tri::Int)

    v = iter.v
    
    face = iter.t.faces[tri]
    neighbours = iter.t.neighs[tri]

    index = face .== v
    w = index[[1,2,3]]
    cw = index[[3,1,2]]

    nexttri, = neighbours[cw]

    if nexttri==-1
        error("The surface is not closed")
    end

    ### Code for extracting vertex from face tri

    face = iter.t.faces[tri]
    cw = (face.==v)[[3,1,2]]
    vi, = face[cw]

    return vi, nexttri
end

function Base.iterate(iter::VertexRing{FaceDS})
    face = iter.start
    return next(iter,face)
end
    
function Base.iterate(iter::VertexRing{FaceDS},ti)
    if ti==iter.start
        return nothing
    else
        return next(iter,ti)
    end
end

function EdgeRing(v::Int,t::FaceDS)
    iter = VertexRing(v,t)
    return PairIterator(iter)
end
