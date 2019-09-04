module TimeToLive

export TTL

using Dates: Period

struct Node{T}
    v::T
    id::Symbol

    Node{T}(v::T) where T = new(v, gensym())
end

Base.:(==)(a::Node, b::Node) = a.v == b.v

"""
    TTL(ttl::Period; refresh_on_access::Bool=true) -> TTL{Any, Any}
    TTL{K, V}(ttl::Period; refresh_on_access::Bool=true) -> TTL{K, V}

A [TTL](https://en.wikipedia.org/wiki/Time_to_live) cache.
If `refresh_on_access` is set, expiries are reset whenever they are accessed.
"""
struct TTL{K, V} <: AbstractDict{K, V}
    d::Dict{K, Node{V}}
    ttl::Period
    refresh::Bool

    function TTL{K, V}(ttl::Period; refresh_on_access::Bool=true) where {K, V}
        return new(Dict{K, Node{V}}(), ttl, refresh_on_access)
    end
    function TTL(ttl::Period; refresh_on_access::Bool=true)
        return TTL{Any, Any}(ttl; refresh_on_access=refresh_on_access)
    end
end

# TODO: These functions have race conditions.
function delete_later(t::TTL, k, v::Node)
    id = v.id
    sleep(t.ttl)
    haskey(t, k) && t.d[k].id === id && delete!(t, k)
end
Base.get(t::TTL, key, default) = haskey(t.d, key) ? t.d[key].v : default
Base.delete!(t::TTL, key) = (delete!(t.d, key); t)
Base.empty!(t::TTL) = (empty!(t.d); t)
Base.getindex(t::TTL, k) = (t.refresh && touch(t, k); t.d[k].v)
Base.getkey(t::TTL, key, default) = getkey(t.d, k)
Base.length(t::TTL) = length(t.d)
Base.pop!(t::TTL) = (p = pop!(t.d); p.first => p.second.v)
Base.pop!(t::TTL, key) = pop!(t.d, key).v
Base.push!(t::TTL, p::Pair) = (t[p.first] =  p.second; t)
Base.sizehint!(t::TTL, newsz) = (sizehint!(t.d, newsz); t)
Base.sort(t::TTL) = sort(Dict(collect(t)))

function Base.iterate(t::TTL, ks=keys(t.d))
    isempty(ks) && return nothing
    k = first(ks)
    return k => t.d[k].v, Iterators.drop(ks, 1)
end

function Base.setindex!(t::TTL{K, V}, v, k) where {K, V}
    node = Node{V}(v)
    @async delete_later(t, k, node)
    return t.d[k] = node
end

# Extras + restrictions.

"""
    touch(t::TTL, k)

Reset the expiry time for the value at `t[k]`.
"""
function Base.touch(t::TTL{K, V}, k) where {K, V}
    t.d[k] = Node{V}(t.d[k].v)  # Change the ID.
    @async delete_later(t, k, t.d[k])
    return nothing
end

# There's no way to properly copy the deletion tasks.
Base.copy(::TTL) = error("TTL cannot be copied")
Base.deepcopy(::TTL) = error("TTL cannot be copied")

end
