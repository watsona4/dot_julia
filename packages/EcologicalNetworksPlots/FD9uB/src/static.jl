"""
    NestedBipartiteLayout

Parameters are

- `align` (whether the two levels should be centered together)
- `relative` (whether the two levels should occupy a length equal to their relative richness)
- `spread` (the distance between the two)

Note that to see the effect of `spread`, you may have to use `aspectratio=1`; if
not, the spacing between levels will be determined by the dimensions of the
plot.
"""
struct NestedBipartiteLayout
    align::Bool
    relative::Bool
    spread::Float64
end

"""
    NestedBipartiteLayout()

By default, a `NestedBipartiteLayout` is aligned, centered, and with a spread of
`1.0`.
"""
NestedBipartiteLayout() = NestedBipartiteLayout(true, true, 1.0)
NestedBipartiteLayout(spread::Float64) = NestedBipartiteLayout(true, true, spread)

function position!(LA::NestedBipartiteLayout, L::Dict{K,NodePosition}, N::T) where {T <: AbstractBipartiteNetwork} where {K}
    r_top = ordinalrank(collect(values(degree(N; dims=1))); rev=true).-1
    r_bot = ordinalrank(collect(values(degree(N; dims=2))); rev=true).-1

    r_top = r_top./maximum(r_top)
    r_bot = r_bot./maximum(r_bot)
    if LA.relative
        if richness(N; dims=2)>richness(N; dims=1)
            r_bot = r_bot .* (richness(N; dims=2)./richness(N; dims=1))
        end
        if richness(N; dims=1)>richness(N; dims=2)
            r_top = r_top .* (richness(N; dims=1)./richness(N; dims=2))
        end
    end

    if LA.align
        r_bot = r_bot .+ (0.5 - (maximum(r_bot)-minimum(r_bot))/2.0)
        r_top = r_top .+ (0.5 - (maximum(r_top)-minimum(r_top))/2.0)
    end

    d_bot = Dict(zip(keys(degree(N; dims=2)), r_bot))
    d_top = Dict(zip(keys(degree(N; dims=1)), r_top))

    d_all = merge(d_bot, d_top)

    for s in species(N)
        L[s].x = d_all[s]
        L[s].y = LA.spread * L[s].y
    end
end
