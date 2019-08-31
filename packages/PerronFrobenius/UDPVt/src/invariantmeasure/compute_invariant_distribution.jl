include("InvariantDistribution.jl")

"""
    left_eigenvector(to::AbstractTransferOperator;
            N::Int = 200,
            tolerance::Float64 = 1e-8,
            delta::Float64 = 1e-8)

Compute the invariant probability distribution from a
`TransferOperator`.

## Computing an invariant probability distribution
The distribution is taken as a left eigenvector of the transfer matrix,
obtained by repeated application of the transfer operator on a randomly
initialised distribution until the probability distribution converges.

## Keyword arguments
- `N`: the maximum number of iterations.
- `tolerance` and `delta: decides when convergence is achieved.

"""
function left_eigenvector(to::AbstractTransferOperator;
			N::Int = 200,
            tolerance::Float64 = 1e-8,
            delta::Float64 = 1e-8)
    #=
    # Start with a random distribution `Ρ` (big rho). Normalise it so that it
    # sums to 1 and forms a true probability distribution over the simplices.
    =#
    Ρ = rand(Float64, 1, size(to.transfermatrix, 1))
    Ρ = Ρ ./ sum(Ρ, dims = 2)

    #=
    # Start estimating the invariant distribution. We could either do this by
    # finding the left-eigenvector of M, or by repeated application of M on Ρ
    # until the distribution converges. Here, we use the latter approach,
    # meaning that we iterate until Ρ doesn't change substantially between
    # iterations.
    =#
    distribution = Ρ * to.transfermatrix

    distance = norm(distribution - Ρ) / norm(Ρ)

    check = floor(Int, 1 / delta)
    check_pts = floor.(Int, transpose(collect(1:N)) ./ check) .* transpose(collect(1:N))
    check_pts = check_pts[check_pts .> 0]
    num_checkpts = size(check_pts, 1)
    check_pts_counter = 1

    counter = 1
    while counter <= N && distance >= tolerance
        counter += 1
        Ρ = distribution

        # Apply the Markov matrix to the current state of the distribution
        distribution = Ρ * to.transfermatrix

        if (check_pts_counter <= num_checkpts &&
           counter == check_pts[check_pts_counter])

            check_pts_counter += 1
            colsum_distribution = sum(distribution, dims = 2)[1]
            if abs(colsum_distribution - 1) > delta
                distribution = distribution ./ colsum_distribution
            end
        end

        distance = norm(distribution - Ρ) / norm(Ρ)
    end
    distribution = dropdims(distribution, dims = 1)

    # Do the last normalisation and check
    colsum_distribution = sum(distribution)

    if abs(colsum_distribution - 1) > delta
        distribution = distribution ./ colsum_distribution
    end

    # Find partition elements with strictly positive measure.
    δ = tolerance/size(to.transfermatrix, 1)
    simplex_inds_nonzero = findall(distribution .> δ)

    # Extract the elements of the invariant measure corresponding to these indices
    return PerronFrobenius.InvariantDistribution(distribution,simplex_inds_nonzero)
end


invariantmeasure = left_eigenvector
export invariantmeasure
