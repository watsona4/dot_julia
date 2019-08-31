"""
    tensordecomp(k::Int, d::Int)

Decomposition of the integers  0:(k^p - 1) in powers of k.


"""
function tensordecomp(k::Int, d::Int)

    sequences = zeros(Int, k^d, d)

    for n = 0:k^d-1
        i = d
        m = n

        while i > 0
            i = i - 1
            j = i
            f = floor(Int, m / k^i)

            while j > 0 && f == 0
                j = j - 1
                f = floor(Integer, m / k^j)
            end

            if f > 0
                sequences[n + 1, j + 1] = f
                i = j
            elseif f == 0
                sequences[n + 1, 1] = m
                i = 0
            end
            m = m - f * k^i
        end
    end

    return sequences
end


"""
    even_sampling_rules(dim::Int, split_factor::Int) -> Array{Float64, 2}

Generate rules for evenly distributed points within a simplex. To do this,
we perform a shape-preserving splitting of the simplex, given a splitting
factor.

Returns the convex expansion coefficients of the points of the resulting
subsimplices in terms of the vertices of the original simplex.
"""
function even_sampling_rules(dim::Int, split_factor::Int)

    sequences::Array{Int, 2} = tensordecomp(split_factor, dim)
    n_seq = size(sequences, 1)

    χ1 = sequences .* (dim + 1)
    χ2 = repeat(transpose(collect(1:dim)), n_seq, 1)
    χ::Array{Int, 2} = χ1 .+ χ2
    χ = sort(χ, dims=2)

    # Define multiplicity matrix M
    M = zeros(Float64, size(χ, 1), size(χ, 2) + 1)
    M[:, 1] = χ[:, 1]
    M[:, 2:(end - 1)] = χ[:, 2:end] - χ[:, 1:(end - 1)]
    M[:, end] = (dim+1)*split_factor * ones(size(χ, 1)) - χ[:, end]

    M = M ./ (split_factor * (dim + 1))

    return copy(transpose(M))
end

"""
Evenly sample points within a simplex by performing a shape-preserving
subdivision of the simplex with a given `split_factor`. If the simplex
lives in a space of dimension `dim`, the resulting number of points is
`split_factor`^(dim).
"""
function evenly_sample(simplex::AbstractArray{Float64, 2}, split_factor::Int)
    dim = size(simplex, 2)
    centroids_exp_coeffs = copy(transpose(even_sampling_rules(dim, split_factor)))
    centroids_exp_coeffs * simplex
end
