const PlainDS = Array{Face{3,Int},1}

struct FaceRing{T}
    v::Int
    t::T # topology
end


"""
    EdgeRing(v,t)

Construct an edge ring iterator at vertex `v` from a given topology `t`. 
"""
struct EdgeRing{T}
    v::Int
    t::T # topology
end


"""
    VertexRing(v,t)

Construct a vertex ring iterator at vertex `v` from a given topology `t`. 
"""
struct VertexRing{T}
    v::Int
    start::Union{Int,Nothing}
    t::T # topology
end

VertexRing(v::Int,t) = VertexRing(v,nothing,t)
### Perhaps one may also consider to make a trait


### With this pairiterator I now can initialize EdgeRing as iterator from VertexRing. 

struct PairIterator
    iter
end

function Base.iterate(iter::PairIterator)
    i1,state1 = iterate(iter.iter)
    i2, state2 = iterate(iter.iter,state1)
    return Face(i1,i2),(state2,i2)
end

function Base.iterate(iter::PairIterator,state)

    if state==nothing
        return nothing        
    end

    state1,i1 = state
    step = iterate(iter.iter,state1)

    if step==nothing
        i2,state2 = iterate(iter.iter)
        return Face(i1,i2), nothing
    else
        i2, state2 = step
        return Face(i1,i2),(state2,i2)
    end
end


function Base.collect(iter::Union{FaceRing,VertexRing})
    collection = Int[] 
    for i in iter
        push!(collection,i)
    end
    return collection
end

function Base.collect(iter::EdgeRing)
    collection = Face{2,Int}[] 
    for i in iter
        push!(collection,i)
    end
    return collection
end

function Base.collect(iter::PairIterator)
    collection = Face{2,Int}[] 
    for i in iter
        push!(collection,i)
    end
    return collection
end

### There is a room for unstructured circulators iterators for performance reasons.

function find_other_triangle_edge(v1::Integer,v2::Integer,skip::Integer,t::PlainDS) 
    for i in 1:length(t)
        if in(v1,t[i]) & in(v2,t[i]) & !(i==skip)
            return i
        end
    end
    return -1
end

function find_triangle_vertex(v::Integer,t::PlainDS) 

    for i in 1:length(t)
        if in(v,t[i])
            return i
        end
    end
    return length(t) + 1 # -1
end
