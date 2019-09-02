function findtwin(edges,e)
    #edges = decompose(Face{2,Int},faces)
    for j in 1:length(edges)
        if edges[j][2]==e[1] && edges[j][1]==e[2]
            return j
        end
    end
end

"""
    EdgeDS(faces::PlainDS)

Constructs and returns edge based datastructure `EdgeDS` from plain face based datastructure PlainDS. Half edge based datastructure `EdgeDS` stores list of edges consisting of base vertex, next edge index and twin edge index.
"""
struct EdgeDS
    edges::Array{Face{3,Int},1} ### It is equal to PlainDS. That is why we should introduce a new type. 
    
    # row is data assciated with edge. It contains a base vertex, next edge and the twin edge
    #neighs::Array{Face{3,Int},1} ### For now keeping simple
    #vfaces::Array{Int,1}
    function EdgeDS(faces::PlainDS)

        edges = decompose(Face{2,Int},faces)

        rows = Face{3,Int}[]

        for ei in edges
            basev = ei[1]
            twin = -1
            for j in 1:length(edges)
                if edges[j][2]==ei[1] && edges[j][1]==ei[2]
                    twin = j
                    break
                end
            end

            ### Now I could find triangle with specific edge
            ### Orientation is important

            ti = findtriangle(faces,ei)
            face = faces[ti]
            nedge = getedge(face,ei)

            next = -1
            for j in 1:length(edges)
                if edges[j]==nedge
                    next = j
                    break
                end
            end

            # @show basev, next, twin
            push!(rows,Face(basev,next,twin))
        end

        return new(rows)
    end

end


function findtriangle(faces::PlainDS,edge)

    equal(v1,v2) = v1==edge[1] && v2==edge[2]
    
    for i in 1:length(faces)
        if in(edge[1],faces[i]) & in(edge[2],faces[i])
            v1,v2,v3 = faces[i]
            if equal(v1,v2) || equal(v2,v3) || equal(v3,v1)
                return i
            end
        end
    end

end

# Returns an edge which we need to look up
function getedge(t,edge)
    v1,v2,v3=t
    if edge==Face(v1,v2)
        return Face(v2,v3)
    elseif edge==Face(v2,v3)
        return Face(v3,v1)
    else
        return Face(v1,v2)
    end
end



### A little bit of thought 

### the state could consist of

### This one would construct the beginign vertex
### So aftger that one is able to do VertexRing(v,t::EdgeDS)

function VertexRing(v::Int,t::EdgeDS)
    edges = t.edges

    for ei in edges
        if v==ei[1]
            next = ei[2]
            return VertexRing(v,next,t)
        end
    end
end

function Base.iterate(iter::VertexRing{EdgeDS})
    e = iter.start
    v = iter.t.edges[e][1]
    return (v,e)
end

function Base.iterate(iter::VertexRing{EdgeDS},e)
    edges = iter.t.edges
    
    ea = edges[e][2]
    eb = edges[ea][3] # the twin
    ec = edges[eb][2]
    
    if ec==iter.start
        return nothing
    else
        return (edges[ec][1],ec)
    end
end
    
function EdgeRing(v::Int,t::EdgeDS)
    iter = VertexRing(v,t)
    return PairIterator(iter)
end


### One would need to mark used rows one by one and loop over the rows. Implementation is rather easy. Also important for exporting.
Faces(t::EdgeDS) = error("Not implemented")

### Selects only edges if their next index is larger to avoid dublications. For simplicity let's not write it as an iterator. 
Edges(t::EdgeDS) = error("Not implemented")
    
