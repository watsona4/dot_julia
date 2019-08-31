
function nontrivial_intersection(dim,N)
    intersecting_volumes = zeros(Float64, N)
    for i = 1:N
        S1,S2 = nontrivially_intersecting_simplices(dim)
        intersecting_volumes[i] = simplexintersection(copy(transpose(S1)), copy(transpose(S2)))
    end
    return intersecting_volumes
end


function shared_vertex_intersection(dim,N)
    intersecting_volumes = zeros(Float64, N)
    for i = 1:N
        S1,S2 = simplices_sharing_vertices(dim)
        intersecting_volumes[i] = simplexintersection(copy(transpose(S1)), copy(transpose(S2)))
    end
    return intersecting_volumes

end
