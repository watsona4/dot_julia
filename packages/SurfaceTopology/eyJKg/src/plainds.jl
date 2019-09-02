@doc "`Faces(t)` returns an iterator for faces from representation of topology `t`" Faces
@doc "`Edges(t)` returns an iterator for edges from representation of topology `t`" Edges


Faces(t::PlainDS) = t
Edges(t::PlainDS) = filter(x->x[1]<x[2],decompose(Face{2,Int},t)) ### Hopefully works

start(iter::FaceRing{PlainDS}) = find_triangle_vertex(iter.v,iter.t)
done(iter::FaceRing{PlainDS},ti::Int) = ti<=length(iter.t) ? false : true

function next(iter::FaceRing{PlainDS},i::Int)
    v = iter.v
    nexti = find_triangle_vertex(iter.v,iter.t[i+1:end]) + i  # possible botleneck here
    return i, nexti
end

Base.iterate(iter::FaceRing{PlainDS}) = next(iter,start(iter))
function Base.iterate(iter::FaceRing{PlainDS},ti::Int)
    if done(iter,ti)
        return nothing
    else
        return next(iter,ti)
    end
end

start(iter::EdgeRing{PlainDS}) = find_triangle_vertex(iter.v,iter.t)
done(iter::EdgeRing{PlainDS},ti::Int) = ti<=length(iter.t) ? false : true

function next(iter::EdgeRing{PlainDS},i::Int)

    v = iter.v
    nexti = find_triangle_vertex(iter.v,iter.t[i+1:end]) + i  # possible botleneck here
    face = iter.t[i]
    w = face.==v
    cw = w[[3,1,2]]
    ccw = w[[2,3,1]]
    
    return (face[cw]...,face[ccw]...), nexti
end

Base.iterate(iter::EdgeRing{PlainDS}) = next(iter,start(iter))
function Base.iterate(iter::EdgeRing{PlainDS},ti::Int)
    if done(iter,ti)
        return nothing
    else
        return next(iter,ti)
    end
end

start(iter::VertexRing{PlainDS}) = find_triangle_vertex(iter.v,iter.t)
done(iter::VertexRing{PlainDS},ti::Int) = ti<=length(iter.t) ? false : true

function next(iter::VertexRing{PlainDS},ti::Int)

    v = iter.v
    faces = iter.t
    face = faces[ti]
    cw = (face.==v)[[3,1,2]]
    vi, = face[cw]
        
    nexti = find_triangle_vertex(iter.v,iter.t[ti+1:end]) + ti  # possible botleneck
    return vi, nexti
end

Base.iterate(iter::VertexRing{PlainDS}) = next(iter,start(iter))
function Base.iterate(iter::VertexRing{PlainDS},ti::Int)
    if done(iter,ti)
        return nothing
    else
        return next(iter,ti)
    end
end
