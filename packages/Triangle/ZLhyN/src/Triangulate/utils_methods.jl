## Utils
function triangle_list_from_marker(flat_triangle_list)
    triangle_list = Array{Array{Int64,1},1}()

    for i in 1:3:length(flat_triangle_list)
        push!(triangle_list, flat_triangle_list[i:i+2])
    end

    return triangle_list
end

function flat_vertices(vertices::Array{Float64,2}, vertices_map::Array{Int64,1})
    vert_size = size(vertices)
    flat_vertices_vector = Vector{Cdouble}(undef, vert_size[1]*vert_size[2])
    
    # for vert_id in vertices_map
    for vert_id=1:vert_size[1]
        flat_vertices_vector[(vert_id*2)-1]=vertices[vert_id]
        flat_vertices_vector[(vert_id*2)]=vertices[vert_id+vert_size[1]]
    end
    
    return flat_vertices_vector
end

function flat_edges(edges::Array{Int64,2})
    edge_size = size(edges)
    flat_edges_vector = Vector{Cint}(undef, edge_size[1]*edge_size[2])

    for edge_id=1:edge_size[1]
        flat_edges_vector[(edge_id*2)-1]=edges[edge_id]
        flat_edges_vector[(edge_id*2)]=edges[edge_id+edge_size[1]]
    end
    
    return flat_edges_vector
end