import LightGraphs
import TikzGraphs

import TikzGraphs.Layouts

export plot_chain
export Layouts

function chain_to_lightgraph(chain)
    g = LightGraphs.DiGraph(state_count(chain))
    for tr in transitions(chain)
        LightGraphs.add_edge!(g, tr.src, tr.dst)
    end
    return g
end

function plot_chain(chain; state_labels=Vector{String}(), transition_labels=Dict{Tuple{Int,Int},String}(),
     state_style="draw, rounded corners, fill=white",
     state_styles=Dict(),
     transition_style="bend left=30",
     transition_styles=Dict(),
     scale=1.5,
     layout=TikzGraphs.Layouts.Layered())
    if length(state_labels) == 0
        for st in states(chain)
            push!(state_labels, string(st))
        end
    end

    if length(transition_labels) == 0
        for tr in transitions(chain)
            transition_labels[(tr.src, tr.dst)] = string(tr.rate)
        end
    end
    g = chain_to_lightgraph(chain)
    TikzGraphs.plot(g; layout=layout,
    labels=state_labels,
    edge_labels=transition_labels,
    node_style=state_style,
    node_styles=state_styles,
    edge_style=transition_style,
    edge_styles=transition_styles,
    options="scale=$scale")
end
