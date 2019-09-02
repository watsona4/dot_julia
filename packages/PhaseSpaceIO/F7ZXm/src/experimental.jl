export Collect
export histmap
export binning
using StatsBase
using ArgCheck

struct Collect
    count::Int64
end

function (c::Collect)(iter)
    ret = eltype(iter)[]
    for (i,xi) in enumerate(iter)
        push!(ret, xi)
        i < c.count || break
    end
    return ret
end

function map_many_functions(getters, particles) where {N}
    map(getters) do f
        map(f, particles)
    end
end

function histmap(getters_particles...;
    edges=nothing,
    closed=:right,
    weight_function=p->p.weight,
    kw...)
    getters = Base.front(getters_particles)
    particles = Base.last(getters_particles)
    data = map_many_functions(getters, particles)
    weight = Weights(map(weight_function, particles))
    # if use_particle_weights
    #     weight = Weights(map(p->p.weight, particles))
    # else
    #     weight = Weights(fill(Float32(1), length(particles)))
    # end
    if edges == nothing
        fit(Histogram, data, weight; closed=closed, kw...)
    else
        fit(Histogram, data, weight, edges; closed=closed, kw...)
    end
end

function Base.filter(f, iter::AbstractPhspIterator; maxlength=10^7)
    if maxlength == nothing
        maxlength = -1
    end
    ret = eltype(iter)[]
    count = 0
    for p in iter
        if count == maxlength
            @warn("maxlength=$maxlength reached. Use `maxlength`=nothing to prevent this.")
            break
        end
        if f(p)
            count += 1
            push!(ret, p)
        else

        end
    end
    ret
end

const Edges{N} = NTuple{N, AbstractVector}
struct Binning{C <: AbstractArray,E <: Edges}
    edges::E
    content::C 
    # Example:
    # 
    # want to bin particles by their x,y coordinates
    # which are between -10 and 10 cm (-15 to 15 for y)
    # In that case we would have say
    # edges = (-10:10, -15:15)
    # content::Matrix{Vector{Particle}}
    # of size (20,30)
    # each cell of content stores the particles that have appropriate
    # x,y coordinates
end

function Base.map(f,b::Binning)
    Binning(b.edges, map(f,b.content))
end

function StatsBase.Histogram(b::Binning)
    closed = :right
    isdensity = false
    Histogram(b.edges, b.content, closed, isdensity)
end

function find_bin_index(edges, key::Number)
    find_bin_index(edges, (key,))
end

function find_bin_index(edges, key)
    map(find_bin_index, edges, key)
end

function find_bin_index(bdries::AbstractVector, key::Number)
    index = searchsortedfirst(bdries, key) - 1
    clamp(index, 1, length(bdries) - 1)
end

function binning_edges_keys_items(edges::NTuple{N}, keys, items) where {N}
    @argcheck length(keys) == length(items)
    T = eltype(items)
    C = Vector{T}
    dims = map(edges) do xs
        length(xs) - 1
    end
    content = Array{Vector{T},N}(undef, dims)
    for i in eachindex(content)
        content[i] = C()
    end
    for (key, item) in zip(keys, items)
        index = find_bin_index(edges, key)
        push!(content[index...], item)
    end
    Binning(edges, content)
end

function get_keys_edges(f, items, nbins::Nothing, edges::Nothing)
    get_keys_edges(f, items, 100, edges)
end

function get_keys_edges(f, items, nbins, edges::Nothing)
    keys = map(f, items)
    kmin,kmax = extrema(keys)
    edges = range(kmin,stop=kmax,length=nbins)
    keys, edges
end

function get_keys_edges(f, items, nbins::Nothing, edges)
    keys = map(f, items)
    keys, edges
end

function get_keys_edges(f, items, nbins, edges)
    @argcheck nbins == length(edges)
    get_keys_edges(f, items, nothing, edges)
end

function binning(f,items; nbins=nothing, edges=nothing)
    keys, edges = get_keys_edges(f, items, nbins, edges)
    binning_edges_keys_items(edges, keys, items)
end
