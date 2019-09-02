using .Graphs

export ContMarkovChain, add_state!, add_transition!, state_count

struct ContMarkovChain
    state_graph::Digraph
    trans_rates::Vector{Float64}
    function ContMarkovChain()
        new(Digraph(), Vector{Float64}())
    end
    function ContMarkovChain(nstates::Integer)
        new(Digraph(nstates), Vector{Float64}())
    end
end

struct Transition
    src::Int
    dst::Int
    rate::Float64
end

add_state!(chain::ContMarkovChain) = add_node!(chain.state_graph)

function add_transition!(chain::ContMarkovChain, src::Integer, dst::Integer, rate::Real)
    idx = add_edge!(chain.state_graph, src, dst)
    push!(chain.trans_rates, rate)
    return idx
end

state_count(chain) = node_count(chain.state_graph)
states(chain) = nodes(chain.state_graph)
function transitions(chain)
    ts = Vector{Transition}()
    for eid in edges(chain.state_graph)
        ep = chain.state_graph.edge_props[eid]
        push!(ts, Transition(ep.src, ep.dst, chain.trans_rates[eid]))
    end
    return ts
end
