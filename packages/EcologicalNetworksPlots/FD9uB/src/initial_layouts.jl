"""
    initial(::Type{RandomInitialLayout}, N::T) where {T <: EcologicalNetworks.AbstractEcologicalNetwork}

Random disposition of nodes in the unit square. This is a good starting
point for any force-directed layout.
"""
function initial(::Type{RandomInitialLayout}, N::T) where {T <: EcologicalNetworks.AbstractEcologicalNetwork}
  return Dict([s => NodePosition() for s in species(N)])
end

"""
    initial(::Type{BipartiteInitialLayout}, N::T) where {T <: EcologicalNetworks.AbstractBipartiteNetwork}

Random disposition of nodes on two levels for bipartite networks.
"""
function initial(::Type{BipartiteInitialLayout}, N::T) where {T <: EcologicalNetworks.AbstractBipartiteNetwork}
  level = NodePosition[]
  for (i, s) in enumerate(species(N))
    this_level = s ∈ species(N; dims=1) ? 1.0 : 0.0
    push!(level, NodePosition(rand(), this_level, 0.0, 0.0))
  end
  return Dict(zip(species(N), level))
end

"""
    initial(::Type{FoodwebInitialLayout}, N::T) where {T <: EcologicalNetworks.AbstractUnipartiteNetwork}

Random disposition of nodes on trophic levels for food webs. Note that the
*fractional* trophic level is used, but the layout can be modified afterwards
to use the continuous levels.
"""
function initial(::Type{FoodwebInitialLayout}, N::T) where {T <: EcologicalNetworks.AbstractUnipartiteNetwork}
  level = NodePosition[]
  tl = fractional_trophic_level(N)
  for (i, s) in enumerate(species(N))
    push!(level, NodePosition(rand(), float(tl[s]), 0.0, 0.0))
  end
  return Dict(zip(species(N), level))
end

"""
    initial(::Type{CircularInitialLayout}, N::T) where {T <: EcologicalNetworks.AbstractEcologicalNetwork}

Random disposition of nodes on a circle. This is the starting point for
circle-based layouts.
"""
function initial(::Type{CircularInitialLayout}, N::T) where {T <: EcologicalNetworks.AbstractEcologicalNetwork}
  level = NodePosition[]
  n = richness(N)
  for (i, s) in enumerate(species(N))
    θ = 2i * π/n
    x, y = cos(θ), sin(θ)
    push!(level, NodePosition(x, y, i))
  end
  return Dict(zip(species(N), level))
end
