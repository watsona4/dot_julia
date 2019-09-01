@recipe function f(network::T) where {T <: AbstractEcologicalNetwork}
   if plotattributes[:seriestype] == :heatmap
      network.A
   end
end

@recipe function f(layout::Dict{K,NodePosition}, network::T;
    nodesize=nothing,
    nodefill=nothing,
    bipartite=false) where {T <: AbstractEcologicalNetwork} where {K}

    # Node positions
    X = [layout[s].x for s in species(network)]
    Y = [layout[s].y for s in species(network)]

    # Default values
    framestyle --> :none
    legend := false

    if typeof(network) <: QuantitativeNetwork
        int_range = (minimum(filter(x -> x > 0.0, network.A)), maximum(network.A))
    end

    if get(plotattributes, :seriestype, :plot) == :plot
        for interaction in network
            y = [layout[interaction.from].y, layout[interaction.to].y]
            x = [layout[interaction.from].x, layout[interaction.to].x]
            @series begin
                seriestype := :line
                linecolor --> :darkgrey
                if typeof(network) <: QuantitativeNetwork
                    linewidth --> EcologicalNetworksPlots.scale_value(interaction.strength, int_range, (0.5, 3.5))
                end
                if typeof(network) <: ProbabilisticNetwork
                    alpha --> interaction.probability
                end
                x, y
            end
        end
    end

    if get(plotattributes, :seriestype, :plot) == :scatter
        @series begin

            if nodesize !== nothing
                nsi_range = (minimum(values(nodesize)), maximum(values(nodesize)))
                markersize := [EcologicalNetworksPlots.scale_value(nodesize[s], nsi_range, (2,8)) for s in species(network)]
            end

            if nodefill !== nothing
                nfi_range = (minimum(values(nodefill)), maximum(values(nodefill)))
                markerz := [EcologicalNetworksPlots.scale_value(nodefill[s], nfi_range, (0,1)) for s in species(network)]
            end

            if bipartite
                m_shape = Symbol[]
                for (i, s) in enumerate(species(network))
                    this_mshape = s ∈ species(network; dims=1) ? :circle : :square
                    push!(m_shape, this_mshape)
                end
                marker := m_shape
            end

            seriestype := :scatter
            color --> :white
            X, Y
        end
    end

end
