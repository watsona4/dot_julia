export poisson_trunc_point, poisson_cum_rtp

function poisson_trunc_point(λ, tol)
    k = 0.0
    expo = -λ
    term = exp(expo)
    term_sum = term
    log_λ = log(λ)
    probs = Vector{Float64}()

    while term_sum < tol / 2.0
        k += 1.0
        expo += log_λ - log(k)
        term = exp(expo)
        term_sum += term
    end

    ltp = Int(k)
    push!(probs, term)

    while 1.0 - term_sum > tol / 2.0
        k += 1.0
        expo += log_λ - log(k)
        term = exp(expo)
        term_sum += term
        push!(probs, term)
    end

    rtp = Int(k)
    @assert length(probs) == (rtp - ltp + 1)

    return ltp, rtp, probs
end


function poisson_cum_rtp(λ, t, tol)
    k = 0.0
    log_λ = log(λ)
    expo = -λ
    term = exp(expo)
    term_sum = term
    probs = Vector{Float64}()

    push!(probs, term)

    while tol < t * (1.0 - term_sum)
        k += 1.0
        expo += log_λ - log(k)
        term = exp(expo)
        term_sum += term
        push!(probs, term)
    end
    rtp = Int(k)
    @assert rtp + 1 == length(probs)
    return rtp, probs
end