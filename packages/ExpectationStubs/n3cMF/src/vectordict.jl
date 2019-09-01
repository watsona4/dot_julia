struct VectorDict{K,V} <: AbstractDict{K,V}
    data::Vector{Pair{K,V}}
end
VectorDict{K,V}() where {K,V} = VectorDict(Vector{Pair{K,V}}())

Base.keys(vd::VectorDict) = first.(vd.data)
Base.values(vd::VectorDict) = last.(vd.data)
Base.haskey(vd::VectorDict, key) = !isempty(get_all_matches(vd, key))

function Base.get(vd::VectorDict, key, default)
    matches = get_all_matches(vd, key)
    if !isempty(matches)
        first(matches)
    else
        default
    end
end

"""
    get_all_matches(vd::VectorDict, key)
Returns all values matching the key
"""
function get_all_matches(vd::VectorDict, key)
    (vv for (kk, vv) in vd.data if isequal(key, kk))
end

function Base.setindex!(vd::VectorDict, value, key)
    # insert it at the front so newest things are matched first
    # old ones are left behind,
    pushfirst!(vd.data, key=>value)
end

Base.iterate(vd::VectorDict) = iterate(vd.data)
Base.iterate(vd::VectorDict, state) = iterate(vd.data, state)

