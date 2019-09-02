using LinearAlgebra
using SparseArrays

function max_out_rate(chain)
    max = 0
    for src in nodes(chain.state_graph)
        total_rate = 0.0
        for edge in out_edges(chain.state_graph, src)
            rate = chain.trans_rates[edge]
            total_rate += rate
        end
        if total_rate > max
            max = total_rate
        end
    end
    return max
end

function trans_prob_matrix(chain, unif_rate)
    rows = Vector{Int}()
    cols = Vector{Int}()
    vals = Vector{Float64}()
    for src in nodes(chain.state_graph)
        total_rate = 0.0
        for edge in out_edges(chain.state_graph, src)
            dst = dst_node(chain.state_graph, edge)
            rate = chain.trans_rates[edge]
            total_rate += rate
            push!(rows, dst)
            push!(cols, src)
            push!(vals, rate / unif_rate)
        end
        push!(rows, src)
        push!(cols, src)
        self_prob = 1.0 - total_rate / unif_rate
        @assert self_prob >= 0
        push!(vals, self_prob)
    end
    dim = node_count(chain.state_graph)
    sparse(rows, cols, vals, dim, dim)
end

function trans_rate_matrix(chain)
    rows = Vector{Int}()
    cols = Vector{Int}()
    vals = Vector{Float64}()
    for src in nodes(chain.state_graph)
        total_rate = 0.0
        for edge in out_edges(chain.state_graph, src)
            dst = dst_node(chain.state_graph, edge)
            rate = chain.trans_rates[edge]
            total_rate += rate
            push!(rows, dst)
            push!(cols, src)
            push!(vals, rate)
        end
        push!(rows, src)
        push!(cols, src)
        push!(vals, -total_rate)
    end
    dim = node_count(chain.state_graph)
    sparse(rows, cols, vals, dim, dim)
end

export fintime_solve_prob, fintime_solve_cum, trans_rate_matrix, trans_prob_matrix, state_prob, state_cumtime

include("poisson_trunc.jl")

struct FintimeProbSolution
    prob::Vector{Float64}
end

struct FintimeCumSolution
    cumtime::Vector{Float64}
end

struct FintimeSolution
    prob::Vector{Float64}
    cumtime::Vector{Float64}
end

function state_prob(sol::Union{FintimeProbSolution, FintimeSolution}, state::Integer)
    return sol.prob[state]
end

function state_cumtime(sol::Union{FintimeCumSolution, FintimeSolution}, state::Integer)
    return sol.cumtime[state]
end

function fintime_solve(chain, init_prob, time)
    prob = fintime_solve_prob(chain, init_prob, time)
    cum = fintime_solve_cum(chain, init_prob, time)
    FintimeSolution(prob.prob, cum.cumtime)
end

function fintime_solve_prob(chain::ContMarkovChain, init_prob, time::Real; unif_rate_factor=1.05, tol=1e-6, ss_check_interval=10)
    @assert unif_rate_factor >= 1.0
    unif_rate = max_out_rate(chain) * unif_rate_factor
    P = trans_prob_matrix(chain, unif_rate)
    prob = fill(0.0, state_count(chain))
    for i in eachindex(init_prob)
        prob[i] = init_prob[i]
    end

    ltp, rtp, poi_probs = poisson_trunc_point(unif_rate * time, tol)

    checkpoint = copy(prob)
    prob_old = copy(prob)

    for k in 0:ltp-1
        prob, prob_old = prob_old, prob
        mul!(prob, P, prob_old)
        if (k + 1) % ss_check_interval == 0
            checkpoint .-= prob
            diff = maximum(abs, checkpoint)
            checkpoint .= prob
            if  diff < tol
                return FintimeProbSolution(prob)
            end
        end
    end
    term_sum = 0.0
    prob_t = fill(0.0, length(prob))
    for k in ltp:rtp
        term = poi_probs[k - ltp + 1]
        term_sum += term
        @. prob_t += term * prob

        prob, prob_old = prob_old, prob
        mul!(prob, P, prob_old)
        if (k - ltp + 1) % ss_check_interval == 0
            @. checkpoint -= prob
            diff = maximum(abs, checkpoint)
            @. checkpoint = prob
            if diff < tol
                @. prob_t += prob * (1.0 - term_sum)
                return FintimeProbSolution(prob_t)
            end
        end
    end

    return FintimeProbSolution(prob_t)
end


function fintime_solve_cum(chain::ContMarkovChain, init_prob, time::Real; unif_rate_factor=1.05, tol=1e-6, ss_check_interval=10)
    unif_rate = max_out_rate(chain) * unif_rate_factor
    P = trans_prob_matrix(chain, unif_rate)
    trans_rate_matrix(chain)
    Matrix{Float64}(P)

    prob = fill(0.0, state_count(chain))
    for i in eachindex(init_prob)
        prob[i] = init_prob[i]
    end
    prob_old = copy(prob)
    checkpoint = copy(prob)

    qt = unif_rate * time
    rtp, poi_probs = poisson_cum_rtp(qt, time, tol)
    right_cum = 1.0 - poi_probs[1]
    sum_right_cum = right_cum


    sol = fill(0.0, length(prob))
    @. sol += right_cum * prob
    ss_reached = false
    for i in 1:rtp
        prob, prob_old = prob_old, prob
        mul!(prob, P, prob_old)

        right_cum -= poi_probs[i + 1]
        sum_right_cum += right_cum

        @. sol += right_cum * prob
        if i % ss_check_interval == 0
            checkpoint .-= prob
            diff = maximum(abs, checkpoint)
            checkpoint .= prob
            if diff < tol
                ss_reached = true
                break;
            end
        end
    end
    sol .*= 1.0 / unif_rate
    if ss_reached
        @. sol += (time - sum_right_cum / unif_rate) * prob
    end
    return FintimeCumSolution(sol)
end
