function origin_coordinates(axisminima, stepsizes, n_intervals_eachaxis)
    D = length(axisminima)
    coords = zeros(Float64, D, prod(n_intervals_eachaxis))

    n_origins_generated = 0
    for i in CartesianRange((n_intervals_eachaxis...,))
        n_origins_generated += 1
        coords[:, n_origins_generated] = axisminima + (stepsizes .* (i.I .- 1))
    end
    return coords
end

"""
	coordinates_of_all_bin_origins(points, ϵ)

Given a set of `points` and a partition scheme `\epsilon`, find the coordinates
of all bins for the rectangular covering of `points`.
"""
function coordinates_of_all_bin_origins(points, ϵ)
    # Make sure that the array contains points as columns.
    if size(points, 1) > size(points, 2)
        error("The dimension of the dataset exceeds the number of points.")
    end
    D = size(points, 1)
    n_pts = size(points, 2)

    axisminima = Vector{Float64}(D)
    top = Vector{Float64}(D)

    for i = 1:D
        axisminima[i] = minimum(points[i, :])
        top[i] = maximum(points[i, :])
    end
    axisminima = axisminima - (top - axisminima) / 100
    top = top + (top - axisminima) / 100

    stepsizes = Vector{Float64}(D)
    if typeof(ϵ) <: Float64
        stepsizes = [ϵ for i in 1:D]
    elseif typeof(ϵ) == Vector{Float64}
        stepsizes = ϵ
    elseif typeof(ϵ) <: Int
        stepsizes = (top - axisminima) / ϵ
    elseif typeof(ϵ) == Vector{Int}
        stepsizes = (top - axisminima) ./ ϵ
    end
    n_intervals_eachaxis = floor.(Int, (top .- axisminima) ./ stepsizes)

    origin_coordinates(axisminima, stepsizes, n_intervals_eachaxis)
end

coordinates_of_all_bin_origins(E::Embeddings.AbstractEmbedding, ϵ) =
	coordinates_of_all_bin_origins(E.points, ϵ)

"""
    μ_of_targetbin_induced_by_binsize_ϵj(
            ϵF::Vector{Float64},
            bin_origin_ϵFₐ::Vector{Float64},
            ϵⱼ::Vector{Float64},
            bin_origins_ϵⱼ::Array{Float64, 2},
            μϵⱼ::Vector{Float64}) -> Float64

Compute the measure of target bin ``b_a`` in the partition defined by `ϵF`
induced by the bin size `ϵⱼ`.

Assume ``P_ϵⱼ`` is the partition associated with the j-th bin size scale,
and that ``P_ϵF`` is the partition associated with the final, target bin
size scale. Then the arguments are:

- `ϵF`: Edge lengths along each of the axes in ``P_ϵF``.
- `bin_origin_ϵFₐ`: Coordinates of origin of the a-th bin in ``P_ϵF``.
- `ϵⱼ`: Edge lengths along each of the axes in ``P_ϵⱼ``.
- `bin_origins_ϵⱼ`: Coordinates of the origin of each of the visited bins
    in ``P_ϵⱼ``. Each column of this array is a bin origin.
- `μϵⱼ`: the measures of the visited bins in ``P_ϵⱼ``.
"""
function μ_of_targetbin_induced_by_binsize_ϵj(
            ϵF::Vector{Float64},
            bin_origin_ϵFₐ::Vector{Float64},
            ϵⱼ::Vector{Float64},
            bin_origins_ϵⱼ::Array{Float64, 2},
            μϵⱼ::Vector{Float64})

    dim = length(ϵF)
    volume_ϵⱼ = prod(ϵⱼ)
    n_visited_bins_ϵⱼ = length(μϵⱼ)
    binning_target_bin1 = falses(n_visited_bins_ϵⱼ)
    binning_target_bin2 = zeros(n_visited_bins_ϵⱼ)
    edges = zeros(Float64, dim + 1)
    sorted_edges = zeros(Float64, dim + 1)
    temp::Vector{Int} = [1, 1, 2, 2]
    T::Vector{Number} = zeros(Number, size(temp))
    intersecting_lengths = zeros(Float64, dim)

    for b = 1:n_visited_bins_ϵⱼ
        for c = 1:dim
            edges[:] = [
                    bin_origin_ϵFₐ[c] + ϵF[c],
                    bin_origin_ϵFₐ[c],
                    bin_origins_ϵⱼ[c, b] + ϵⱼ[c],
                    bin_origins_ϵⱼ[c, b]
                    ]
            sorted_edges = sort(edges, rev = true)
            permutation = sortperm(edges, rev = true)

            T[:] = temp[permutation]
            if T[1] != T[2]
                intersecting_lengths[c] = sorted_edges[2] - sorted_edges[3]
            else
                intersecting_lengths[c] = 0
            end
            temp[:] = [1, 1, 2, 2]
        end

        intersecting_volume = prod(intersecting_lengths)
        if intersecting_volume > 0
            binning_target_bin1[b] = true
            binning_target_bin2[b] = intersecting_volume
        end
    end
    ρₐ = transpose(μϵⱼ[binning_target_bin1]) *
        binning_target_bin2[binning_target_bin1]/volume_ϵⱼ
end



"""
    μ_of_targetbins_induced_by_binsize_ϵj(ϵF::Vector{Float64},
                            bin_origins_ϵF::Vector{Float64},
                            ϵⱼ::Vector{Float64},
                            bin_origins_ϵⱼ::Array{Float64, 2},
                            μϵⱼ::Vector{Float64})

Compute the measure of the bins in the grid defined by `ϵF` induced
by another bin size `ϵⱼ`.

Assume ``Pϵⱼ`` is the partition associated with the j-th bin size scale,
and that ``PϵF`` is the partition associated with the final, target bin
size scale. Then the arguments are:

- `ϵF`: Edge lengths along each of the axes in ``PϵF``.
- `bin_origins_ϵF`: Coordinates of origin of the a-th bin in ``PϵF``.
- `ϵⱼ`: Edge lengths along each of the axes in ``Pϵⱼ``.
- `bin_origins_ϵⱼ`: Coordinates of the origin of each of the visited bins
    in ``Pϵⱼ``. Each column of this array is a bin origin.
- `μϵⱼ`: the measures of the visited bins in ``Pϵⱼ``.
"""
function μ_of_targetbins_induced_by_binsize_ϵj(
            E::Embeddings.AbstractEmbedding,
            ϵF,
            bin_origins_ϵF::Array{Float64, 2},
            ϵⱼ,
            bin_origins_ϵⱼ::Array{Float64, 2},
            μϵⱼ::Vector{Float64})

    ϵF = minima_and_stepsizes(E.points, ϵF)[2]
    ϵⱼ = minima_and_stepsizes(E.points, ϵⱼ)[2]
    n = size(bin_origins_ϵF, 2)
    ρ = zeros(Float64, n)
    for i = 1:n
        ρ[i] = μ_of_targetbin_induced_by_binsize_ϵj(
                    ϵF, bin_origins_ϵF[:, i], ϵⱼ, bin_origins_ϵⱼ, μϵⱼ)
    end
    ρ
end


"""
    μϵF_induced_by_ϵj(E::Embeddings.AbstractEmbedding,
                    ϵF::Vector{Float64},
                    ϵⱼ::Vector{Float64})

Calculate the measure of the bins at bin size scale `ϵF` induced
by the bin size scale `ϵⱼ`.
"""
function μϵF_induced_by_ϵj(E::Embeddings.AbstractEmbedding, ϵF, ϵⱼ)
    ϵF = minima_and_stepsizes(E.points, ϵF)[2]
    ϵⱼ = minima_and_stepsizes(E.points, ϵⱼ)[2]

    # All possible bins in the final partition given by ϵF
    bins_ϵF = coordinates_of_all_bin_origins(E, ϵF)

    # The unique bins visisted by the orbit in the partition given by ϵⱼ
    bins_ϵⱼ = unique(assign_coordinate_labels(E, ϵⱼ), 2)

    # The transfer operator in the partition given by ϵⱼ
    TOϵⱼ = transferoperator_grid(E, ϵⱼ)

    # The measure of the of the visited bins in the partition given by ϵⱼ
    μϵⱼ = left_eigenvector(TOϵⱼ).dist

    μ_of_targetbins_induced_by_binsize_ϵj(E, ϵF, bins_ϵF, ϵⱼ, bins_ϵⱼ, μϵⱼ)
end

"""
μϵF_induced_by_ϵj(E::Embeddings.AbstractEmbedding,
                             ϵF::Vector{Float64},
                             ϵⱼs::Vector{Vector{Float64}})

Compute the invariant measure for the partition specified by
`ϵF`. The measure is obtained by averaging the measure over
partitions `ϵⱼs`.
"""
function μϵF_induced_by_ϵjs(E::Embeddings.AbstractEmbedding, ϵF, ϵⱼs)#,
                             #visited_bin_inds_ϵF::Vector{Int})
    n_partitions = length(ϵⱼs)

    #μ_across_binsizes = Vector{Vector{Float64}}(n_partitions)
    #for i=1:n_partitions
    #    μ_across_binsizes[i] = μϵF_induced_by_ϵⱼ(E, ϵF, ϵⱼs[i])
    #end

    μ_across_binsizes = pmap(ϵⱼ -> μϵF_induced_by_ϵj(E, ϵF, ϵⱼ), ϵⱼs)

    # Gather in a matrix and transpose. Now the i-th column
    # and a-th row give the measure indiced for the i-th
    # state of the target partition induced by the a-th
    # bin size ϵₐ.
    μ = transpose(hcat(μ_across_binsizes...,))

    # Compute the average measure for the final partition
    n_states_μF = size(μ, 2)

    μF = Vector{Float64}(n_states_μF)
    for i in 1:n_states_μF
        μF[i] = (1/n_partitions) * sum(μ[:, i])
    end

    return μF
end


export μϵF_induced_by_ϵjs,
    μϵF_induced_by_ϵj,
    coordinates_of_all_bin_origins
