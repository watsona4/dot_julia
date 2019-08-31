"""
# k = the size reducing factor.
# d = dimension
# Finds all the possible ways of
"""
function simplex_split(k::Int, d::Int; orientations = false)

    sequences::Array{Int, 2} = tensordecomp(k, d)
    n_seq = size(sequences, 1)

    χ1 = sequences .* (d + 1)
    χ2 = repeat(transpose(collect(1:d)), n_seq, 1)
    χ::Array{Int, 2} = χ1 .+ χ2
    χ = sort(χ, dims=2)

    matrices_simplicial_subdivision::Array{Int, 2} = zeros((d + 1) * k^d, k)

    for a = 1:n_seq
        tmp = ones(Int, k * (d+1))
        for b = 1:(d-1)
            tmp[(χ[a, b] + 1):(χ[a, b+1])] = (b+1) * ones(χ[a, b+1] - χ[a, b], 1)
        end

        tmp[(χ[a, d]+1):size(tmp, 1)] = (d+1) * ones(size(tmp, 1) - χ[a, d], 1)

        indices = ((a-1) * (d + 1) + 1):(a*(d + 1))
        matrices_simplicial_subdivision[indices, :] = reshape(tmp, d + 1, k)
    end


    simplex_orientations = zeros(Float64, k^d, 1)
    Χ_values = zeros(Int, d, 1)

    for i = 1:size(simplex_orientations, 1)
        indices::Vector{Int} = ((d+1) * (i - 1) + 1):((d + 1) * i)
        Χi = matrices_simplicial_subdivision[indices, :]

        ΔΧi = (Χi[2:(d+1), :] - Χi[1:d, :]) .* repeat(transpose(collect(1:k)), d, 1)

        transition_ind = round.(Int, ΔΧi * ones(k, 1))

        M = zeros(d, d)

        for j = 1:d
            Χ_values[j] =  Χi[j, transition_ind[j]]
            M[j, Χ_values[j]] = 1
        end

        simplex_orientations[i] = det(M) / k^d
    end


    if orientations # Should the orientations of the simplices also be returned?
        return matrices_simplicial_subdivision, simplex_orientations
    else
        return matrices_simplicial_subdivision
    end

end
