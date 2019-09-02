module Example
import Random

"""
    MyPareto(alpha::Float64,x0::Float64)

Pareto distribution for sampling. This does not depend on Distributions and
the RNG seed can be set. This may not be needed for future versions of Julia.
"""
struct MyPareto
    alpha::Float64
    x0::Float64
end
MyPareto(alpha=1.0) = MyPareto(alpha, 1.0)
Random.rand(p::MyPareto) = p.x0 * Random.rand()^(-one(p.alpha) / p.alpha)

"""
    makeparetodata()

Create a reproducible sorted array of Pareto distribution samples.
"""
function makeparetodata(alpha=0.5, seed=11)
    Random.seed!(seed)
    d = MyPareto(alpha)
    return [Random.rand(d) for _=1:10^6] |> sort!
end

end # module Example
