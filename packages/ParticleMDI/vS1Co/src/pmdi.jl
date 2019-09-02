using DelimitedFiles
using Distributions
using IterTools
using NonUniformRandomVariateGeneration
using Printf
using Random
using SpecialFunctions
using Statistics
using StatsBase

"""
`pmdi(dataFiles, dataTypes, N::Int64, particles::Int64,
ρ::Float64, iter::Int64, outputFile::String, initialise::Bool,
output_freq::Int64)`
Runs particleMDI on specified datasets
## Input
- `dataFiles::Vector` a vector of K data matrices to be analysed
- `dataTypes::Vector` a vector of K datatypes. Independent multivariate normals can be
specified with `particleMDI.gaussianCluster`
- `N::Int64` the maximum number of clusters to fit
- `particles::Int64` the number of particles
- `ρ::Float64` proportion of allocations assumed known in each MCMC iteration
- `iter::Int64` number of iterations to run
- `outputFile::String` specification of a CSV file to store output
- `featureSelect::Bool` flag for performing feature selection. All datatypes must support this. Default is false.
## Output
Outputs a .csv file, each row containing:
- Mass parameter for datasets `1:K`
- Φ value for `binomial(K, 2)` pairs of datasets
- c cluster allocations for observations `1:n` in datasets `1:k`
Returns `K` vectors of `d_k` feature selection probabilities.
"""
function pmdi(dataFiles, dataTypes, N::Int64, particles::Int64,
    ρ::Float64, iter::Int64, outputFile::String, featureSelect::Bool = false)

    K       = length(dataFiles) # No. of datasets
    n_obs   = size(dataFiles[1], 1)

    @assert length(dataTypes) == K "Number of datatypes not equal to number of datasets"
    @assert all(x->x==n_obs, [size(dataFiles[k])[1] for k = 1:K]) "Datasets don't have same number of observations. Each row must correspond to the same underlying observational unit across datasets."
    @assert (ρ < 1) && (ρ > 0) "ρ must be between 0 and 1"
    @assert (N <= n_obs) & (N > 1) "Number of clusters must be greater than 1 and not greater than the number of observations"
    @assert particles > 1 "Conditional particle filter requires 2 or more particles"

    # Initialise the hyperparameters
    M = ones(Float64, K) .* 2 # Mass parameter
    γc = rand(Gamma(1.0 / N, 1), N, K) .+ eps(Float64) # Component weights
    Φ = K > 1 ? rand(Gamma(1, 0.2), Int64(K * (K - 1) * 0.5)) : zeros(1) # Dataset concordance measure

    # Initialise allocations randomly according to γc
    s = Matrix{Int64}(undef, n_obs, K)
    for k = 1:K
        s[:, k] = sampleCategorical(n_obs, γc[:, k])
    end

    # Get a matrix of all combinations of allocations
    c_combn = Matrix{Int64}(undef, N ^ K, K)
    for k in 1:K
        c_combn[:, K - k + 1] = div.(0:(N ^ K - 1), N ^ (K - k)) .% N .+ 1
    end

    # The corresponding gammas
    Γc = Matrix{Float64}(undef, N ^ K, K)
    for k = 1:K
        Γc[:, k] = log.(γc[:, k][c_combn[:, k]])
    end

    # Which Φ value is activated by each of the above combinations
    Φ_index = K > 1 ? Matrix{Bool}(undef, N ^ K, Int64(K * (K - 1) / 2)) : fill(1, (N, 1))
    if K > 1
        i = 1
        for k1 in 1:(K - 1)
            for k2 in (k1 + 1):K
                Φ_index[:, i] = (c_combn[:, k1] .== c_combn[:, k2])
                i += 1
            end
        end
    end

    # Normalising constant
    Z = update_Z(Φ, Φ_index, Γc)
    v = update_v(n_obs, Z)

    # Particle weights
    logweight = zeros(Float64, particles)
    # Ancestor weights for ancestor sampling
    ancestor_weights = zeros(Float64, particles)
    # Mutation weights
    logprob = [Vector{Float64}(undef, N * particles + 1) for k in 1:K]
    # Feature selection index
    featureFlag = [rand(Bool, size(dataFiles[k], 2)) for k in 1:K]
    if !featureSelect
        for k in 1:K
            featureFlag[k] .= true
        end
    end
    # Feature select probabilities
    featureProb = [zeros(Float64, size(dataFiles[k], 2)) for k in 1:K]
    featurePosterior = [featureFlag[k] ./ (iter + 1) for k in 1:K]

    # particle matches the cluster labels to the cluster IDs
    particle = [fill(1, (N, particles)) for k in 1:K]
    logprob_particle = [Matrix{Float64}(undef, N, particles) for k in 1:K]

    # A vector containing all of the clusters
    clusters = [Vector{dataTypes[k]}(undef, N * particles + 1) for k in 1:K]

    sstar_id = Matrix{Int64}(undef, particles, K)
    sstar = zeros(Int64, particles, n_obs, K)
    out = [map(x -> @sprintf("MassParameter_%d", x), 1:K);
               map((x, y) -> @sprintf("phi_%d_%d", x, y),
               calculate_Φ_lab(K)[:, 1],
               calculate_Φ_lab(K)[:, 2]);
               "ll";
               map((x, y) -> @sprintf("K%d_n%d", x, y),
               repeat(1:K, inner = n_obs),
               repeat(1:n_obs, outer = K))]
    out =  reshape(out, 1, length(out))
    writedlm(outputFile, out, ',')
    fileid = open(outputFile, "a")
    ll = 0
    ll1 = time_ns()
    writedlm(fileid, [M; Φ; ll;  s[1:(n_obs * K)]]', ',')

    order_obs = collect(1:n_obs)
    n1 = floor(Int, ρ * n_obs)

    @inbounds for it in 1:iter
        for k in 1:K
            for i in eachindex(particle[k])
                particle[k][i] = 1
            end
        end
        shuffle!(order_obs)

        # Update hyperparameters
        update_Φ!(Φ, v, s, Φ_index, γc, K, Γc)
        update_γ!(γc, Φ, v, M, s, Φ_index, c_combn, Γc, N, K)
        Π = γc ./ sum(γc, dims = 1)
        Z = update_Z(Φ, Φ_index, Γc)
        v = update_v(n_obs, Z)
        update_M!(M, γc, K, N)

        log_γ = log.(γc)

        for k = 1:K
            for i = 1:(N ^ K)
                Γc[i, k] = log_γ[c_combn[i, k], k]
            end
        end


        for k = 1:K
            clusters[k][1] = dataTypes[k](dataFiles[k])
            id = 2
            us = unique(s[order_obs[1:(n1 - 1)], k])
            for u in us
                clusters[k][id] = dataTypes[k](dataFiles[k])
                id += 1
            end
            for i in order_obs[1:(n1 - 1)]
                id = findall((in)(s[i, k]), us)[1] + 1
                cluster_add!(clusters[k][id], dataFiles[k][i, :], featureFlag[k])
                particle[k][s[i, k], :] .= id
                sstar[:, i, k] .= s[i, k]
            end
        end

        @inbounds for i in order_obs[n1:n_obs]
            for k in 1:K
                obs = dataFiles[k][i, :]
                for id in 1:maximum(particle[k])
                    logprob[k][id] = calc_logprob(obs, clusters[k][id], featureFlag[k])
                end
                logprob_particle[k] = logprob[k][particle[k]]

                # Draw the new allocations
                for p in 1:particles
                    fprob = logprob_particle[k][:, p]
                    max_logprob = maximum(fprob)
                    for n in 1:N
                        @fastmath fprob[n] = Π[n, k] * exp(fprob[n] - max_logprob)
                    end
                    logweight[p] += log(sum(fprob)) + max_logprob
                    # Set reference trajectory
                    if p != 1
                        new_s = sample(1:N, Weights(fprob))
                    else
                        new_s = s[i, k]
                    end
                    sstar_id[p, k] = particle[k][new_s, p]
                    sstar[p, i, k] = new_s
                end

                # Add observation to new cluster
                max_k = maximum(particle[k])
                for p in unique(sstar_id[:, k])
                    if wipedout(particle[k], sstar_id[:, k], p)
                        # If the origin cluster still exists somewhere
                        # Need to create a new cluster
                        # with obs added to it
                        id = p
                    else
                        id = max_k + 1
                        clusters[k][id] = deepcopy(clusters[k][p])
                        max_k += 1
                    end
                    cluster_add!(clusters[k][id], obs, featureFlag[k])
                    for part in 1:particles
                        if particle[k][sstar[part, i, k], part] == p
                            particle[k][sstar[part, i, k], part] = id
                        end
                    end
                end
            end

            Φ_upweight!(logweight, sstar[:, i, :], K, Φ, particles)

            # Resampling
            if calc_ESS(logweight) <= - 0.5 * particles
                partstar = draw_partstar(logweight, particles)
                logweight .= 1.0
                for k in 1:K
                    particle[k] = particle[k][:, partstar]
                    for (i, id) in enumerate(1:(maximum(particle[k])))
                        if id !== i
                            for j in eachindex(particle[k])
                                if particle[k][j] == id
                                    particle[k][j] = i
                                end
                            end
                            clusters[k][i] = deepcopy(clusters[k][id])
                        end
                    end
                end
            end
        end

        # Select a single particle
        p_star = sample(1:particles, Weights(exp.(logweight .- maximum(logweight))))

        # Feature selection
        ## Create a null particle with every obs in one cluster
        if featureSelect
            nullCluster = [dataTypes[k](dataFiles[k]) for k in 1:K]
            for k = 1:K
                featureFlag[k] .= true
                for i = 1:n_obs
                    cluster_add!(nullCluster[k], dataFiles[k][i, :], featureFlag[k])
                end
                featureProb[k] = - calc_logmarginal(nullCluster[k])
            end
            ## Compare this to the marginal likelihood for each cluster
            for k = 1:K
                occupiedClusters = unique(sstar[p_star, :, k])
                for clust in occupiedClusters
                    clust_members = findindices(sstar[p_star, :, k], clust)
                    clust_params = dataTypes[k](dataFiles[k])
                    for obs in clust_members
                        cluster_add!(clust_params, dataFiles[k][obs, :], featureFlag[k])
                    end
                    featureProb[k] += calc_logmarginal(clust_params)
                end
                featureFlag[k] = (1 .- 1 ./ (exp.(featureProb[k] .+ 1))) .> rand(length(featureProb[k]))
                featurePosterior[k] += featureFlag[k] ./ (iter + 1)
            end
        end

        logweight .= 1.0
        s[:] = sstar[p_star, :, :]
        # Match up labels across datasets
        align_labels!(s, Φ, γc, N, K)

        ll = (time_ns() - ll1) / 1.0e9
        writedlm(fileid, [M; Φ; ll; s[1:(n_obs * K)]]', ',')
    end
    close(fileid)
    return featurePosterior
end
