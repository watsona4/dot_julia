"""
    CircularLayout

A circular layout has a single field, `radius`.
"""
struct CircularLayout
    radius::Float64
end

"""
    CircularLayout()

Create a circular layout with a radius of 1.
"""
CircularLayout() = CircularLayout(1.0)

function nodeangle(x, y)
    hyp = sqrt(x*x + y*y)
    θ = x < 0.0 ? π - asin(y/hyp) : asin(y/hyp) + 2π
    return θ
end

nodeangle(n::NodePosition) = nodeangle(n.x, n.y)

"""
    position!(LA::CircularLayout, L::Dict{K,NodePosition}, N::T) where {T <: AbstractEcologicalNetwork} where {K}

Nodes will be positioned at equal distances along a circle, and nodes that
are densely connected will be closer to one another. This is an efficient
way to represent modular networks.

#### References

McGuffin, M.J., 2012. Simple algorithms for network visualization: A tutorial.
Tsinghua Science and Technology 17, 383–398.
https://doi.org/10.1109/TST.2012.6297585
"""
function position!(LA::CircularLayout, L::Dict{K,NodePosition}, N::T) where {T <: AbstractEcologicalNetwork} where {K}
    S = richness(N)
    Θ = Dict([s => nodeangle(L[s]) for s in species(N)])
    for (i, n1) in enumerate(species(N))
        θ = L[n1].r*2π/S
        sx, sy = cos(θ), sin(θ)
        nei = Set{last(eltype(N))}[]
        if n1 ∈ species(N; dims=2)
            nei = union(nei, N[:,n1])
        end
        if n1 ∈ species(N; dims=1)
            nei = union(nei, N[n1,:])
        end
        for (j, n2) in enumerate(nei)
            θ2 = L[n2].r*2π/S
            sx = sx + cos(θ2)
            sy = sy + sin(θ2)
        end
        Θ[n1] = mean(nodeangle(sx, sy))
    end
    m = minimum(collect(values(Θ)))
    M = maximum(collect(values(Θ)))
    for n in species(N)
        Θ[n] = (Θ[n]-m)/(M-m)*2π+rand()*0.001
    end
    v = collect(values(Θ))
    r = ordinalrank(v)
    R = Dict(zip(v, r))
    for n in species(N)
        i = 2*R[Θ[n]] * π/S
        x, y = LA.radius*cos(i), LA.radius*sin(i)
        L[n] = NodePosition(x, y)
    end
end
