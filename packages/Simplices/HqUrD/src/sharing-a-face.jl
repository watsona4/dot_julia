function SharedFaceVolume(S₂::AbstractArray{T, 2},
            αs_S₁vertices_intermsof_S₂vertices::AbstractArray{Float64, 2},
            ordered_vertex_indices_S1::AbstractVector{Int},
            ordered_vertex_indices_S2::AbstractVector{Int}) where {T}

    # Indices of the nonshared vertices in simplex 1 (label it u)
    # and in simplex 2 (label it v)
    n_vertices  = size(S₂, 2)
    idx_u = ordered_vertex_indices_S1[n_vertices]
    idx_v = ordered_vertex_indices_S2[n_vertices]

    αᵤ = αs_S₁vertices_intermsof_S₂vertices[:, idx_u]
    last_α = αᵤ[idx_v]
    shared_vertex_inds_in_S2 = ordered_vertex_indices_S2[1:n_vertices-1]

    # If last coefficient is zero or negative, then the simplices intersect
	# in the shared face. So we just have to consider
	if last_α <= 0.0
		return 0.0
    else
        inds_positive_coeffs = findall(αᵤ .> 0)
        positive_coeffs = αᵤ[inds_positive_coeffs]

        # One can prove that the intersection in the nontrivial case (last_α > 0)
        # is a new simplex. This means that there will be only one extra
        # intersecting point. It is the convex combination of the points
        # with strictly positive convex expansion coefficients with those
        # coefficients (hence, the normalisation to get convexity).
        intpt = (S₂[:, inds_positive_coeffs] * positive_coeffs) ./ sum(positive_coeffs)

        return abs(det([ones(1, n_vertices);
                        [S₂[:, shared_vertex_inds_in_S2] intpt]]))
    end
end

function SharedFaceVertices(S₂::AbstractArray{T, 2},
            αs_S₁vertices_intermsof_S₂vertices::AbstractArray{Float64, 2},
            ordered_vertex_indices_S1::AbstractVector{Int},
            ordered_vertex_indices_S2::AbstractVector{Int}) where {T}

    # Indices of the nonshared vertices in simplex 1 (label it u)
    # and in simplex 2 (label it v)
    n_vertices  = size(S₂, 2)
    idx_u = ordered_vertex_indices_S1[n_vertices]
    idx_v = ordered_vertex_indices_S2[n_vertices]

    αᵤ = αs_S₁vertices_intermsof_S₂vertices[:, idx_u]
    last_α = αᵤ[idx_v]
    shared_vertex_inds_in_S2 = ordered_vertex_indices_S2[1:n_vertices-1]

    # If last coefficient is zero or negative, then the simplices intersect
	# in the shared face. So we just have to consider
	if last_α <= 0.0
		return Float64[]
    else
        inds_positive_coeffs = findall(αᵤ .> 0)
        positive_coeffs = αᵤ[inds_positive_coeffs]

        # One can prove that the intersection in the nontrivial case (last_α > 0)
        # is a new simplex. This means that there will be only one extra
        # intersecting point. It is the convex combination of the points
        # with strictly positive convex expansion coefficients with those
        # coefficients (hence, the normalisation to get convexity).
        intpt = (S₂[:, inds_positive_coeffs] * positive_coeffs) ./ sum(positive_coeffs)

        return [S₂[:, shared_vertex_inds_in_S2] intpt]
    end
end
