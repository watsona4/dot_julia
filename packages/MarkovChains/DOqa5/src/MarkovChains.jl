module MarkovChains

# package code goes here
include("graphs.jl")
include("markov_chain.jl")
include("inftime_solve.jl")
include("fintime_solve.jl")
include("plot.jl")

struct CtmcSolution
    prob::Vector{Float64}
    cumtime::Vector{Float64}
end

export solve, state_prob, state_cumtime

function state_prob(sol::CtmcSolution, state::Integer)
    return sol.prob[state]
end

function state_cumtime(sol::CtmcSolution, state::Integer)
    return sol.cumtime[state]
end



function solve(chain, init_prob, time)
    n = state_count(chain)
    prob = Vector{Float64}(undef, n)
    cumtime = Vector{Float64}(undef, n)
    if isinf(time)
        sol = inftime_solve(chain, init_prob)
        for i in 1:n
            prob[i] = state_prob(sol, i)
            cumtime[i] = state_cumtime(sol, i)
        end
    else
        sol = fintime_solve(chain, init_prob, time)
        for i in 1:n
            prob[i] = state_prob(sol, i)
            cumtime[i] = state_cumtime(sol, i)
        end
    end
    CtmcSolution(prob, cumtime)
end

export Graphs

end # module
