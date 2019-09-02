function update_v(n_obs::Int64, Z::Float64)
    return rand(Gamma(n_obs, 1 / Z))
end

function update_M!(M::Array, γ::Array, K::Int64, N::Int64)
    # Update the mass parameter
    prior = [2, 0.25]
    for k = 1:K
        @inbounds current_γ = γ[:, k]
        current_M = Float64(M[k])
        log_likelihood = - sum(logpdf.(Gamma(current_M / N, 1.0), current_γ))
        log_likelihood_0 = - sum(logpdf.(Gamma(prior[1], prior[2]), current_M))
        proposed_mass = (current_M + rand(Normal()) / 10)
        if proposed_mass <= 0.0
            alpha = 0.0
        else
            new_log_likelihood = - sum(logpdf.(Gamma(proposed_mass / N, 1), current_γ))
            new_log_likelihood_0 = - sum(logpdf(Gamma.(prior[1], prior[2]), proposed_mass))
            alpha = exp(-new_log_likelihood - new_log_likelihood_0 + log_likelihood + log_likelihood_0)
        end
        if rand() < alpha
            M[k] = proposed_mass
        end
    end
    return
end


@inline function update_Z(Φ::Array, Φ_index::Array, Γ::Array)
    # Update the normalising constant
    # Z = sum(exp.((Φ_index * (log.(Φ .+ 1)) + sum(Γ, dims = 2))))
    Φ_log = log.(Φ .+ 1)
    norm_temp = Φ_index * Φ_log + sum(Γ, dims = 2)
    Z = 0.0
    for i in eachindex(norm_temp)
        Z += exp(norm_temp[i])
    end
    return Z
end

function calculate_likelihood(s::Array, Φ::Array, γ::Array, Z::Float64)
    likelihood = zeros(Float64, (size(s, 1)))
    Φ_log = similar(Φ)
    for i in eachindex(Φ)
        Φ_log[i] = log(1 + Φ[i])
    end
    for i in 1:size(s, 1)
        for k in 1:size(s, 2)
            likelihood[i] += log(γ[s[i, k], k])
        end
        if size(s, 2) > 1
            ϕ = 1
            for k1 in 1:(size(s, 2) - 1)
                for k2 in (k1 + 1):(size(s, 2))
                    likelihood .+= Φ_log[ϕ] * s[i, k1] == s[i, k2]
                    ϕ += 1
                end
            end
        end
    end
    return sum(exp.(likelihood) ./ Z)
end

function update_γ!(γ::Array, Φ::Array, v::Float64, M, s::Array, Φ_index::Array, γ_combn::Array, Γ::Array, N::Int64, K::Int64)
    β_0 = 1.0
    Φ_log = log.(Φ .+ 1)
    α_star = Matrix{Float64}(undef, N, K)
    for k = 1:K
        for n = 1:N
            # @inbounds α_star[n, k] = α_0 + sum(s_k .== n)
            # @inbounds α_star[n, k] = M[k] / N + sum(s[:, k] .== n)
            @inbounds α_star[n, k] = M[k] / N + countn(s[:, k], n)
        end
    end
    norm_temp = Φ_index * Φ_log + sum(Γ, dims = 2)
    for i in eachindex(norm_temp)
        norm_temp[i] = exp(norm_temp[i])
    end
    @inbounds for k = 1:K
         pertinent_rows = findZindices(k, K, 1, N)
         for n = 1:N
            old_γ = γ[n, k] + 0.0
            β_star = β_0 + v * sum((norm_temp[pertinent_rows])) / γ[n, k]
            γ[n, k] = rand(Gamma(α_star[n, k], 1 / β_star)) + eps(Float64)
            for i in pertinent_rows
                norm_temp[i] *= γ[n, k] / old_γ
            end
            pertinent_rows .+= N ^ (k - 1)
        end
    end
    return
end


function update_Φ!(Φ, v::Float64, s, Φ_index, γ, K::Int64, Γ)
    # Prior parameters
    if K == 1
        return
    else
        # Prior parameters
        α_0 = 1.0
        β_0 = 5.0
        Φ_lab = calculate_Φ_lab(K)
        Φ_log = log.(Φ .+ 1)
        norm_temp = Φ_index * Φ_log + sum(Γ, dims = 2)
        for i in eachindex(norm_temp)
            @inbounds norm_temp[i] = exp(norm_temp[i])
        end
        @inbounds for i in 1:length(Φ)
            # Get relevant allocations
            # current_allocations = s[:, Φ_lab[i, :]]
            Φ_current = Φ[i] + 0.0
            # n_agree = sum(current_allocations[:, 1] .== current_allocations[:, 2])
            n_agree = 0
            for j in 1:size(s, 1)
                # For some reason checking if the difference is zero
                # is quicker/fewer allocations than checking if the
                # two are equal
                # Perhaps it removes checks for types?
                n_agree += (s[j, Φ_lab[i, 1]] - s[j, Φ_lab[i, 2]]) == 0
            end
            # Get relevant terms in the normalisation constant
            pertinent_rows = findall(Φ_index[:, i])
            β_star = β_0 + v * sum(norm_temp[pertinent_rows, :]) / (1 + Φ_current)
            weights = lgamma.((0:n_agree) .+ α_0)
            weights += logpdf.(Binomial(n_agree, 0.5), 0:n_agree)
            weights -= (0:(n_agree)) .* log(β_star)
            α_star = α_0 + n_agree
            Φ[i] = rand(Gamma(α_star, 1 / β_star)) + eps(Float64)
            # Update the normalising constant values to account for this update
            norm_temp[pertinent_rows, :] .*= (1 + Φ[i]) / (1 + Φ_current)
        end
    end
    return
end
