module BackedUpImmutable

export StaticDict, BackedUpImmutableDict, getindex, setindex!, get!, get, restore!, restoreall!


""" Another name for ImmutableDict, but here as with an extra constructor. """
StaticDict = Base.ImmutableDict

""" Constructor for StaticDict / ImmutableDict to take an array of key value pairs. """
function Base.ImmutableDict(pairs::Vector{Pair{K,V}}) where V where K
    id = Base.ImmutableDict(pairs[1][1] => pairs[1][2])
    for p in pairs[2:end]
        id = StaticDict(id, p[1] => p[2])
    end
    id
end

""" Constructor for StaticDict to take a series of pairs, varargs style """
function Base.ImmutableDict(pairs...)
    pairvect = [pairs...]
    id = Base.ImmutableDict(pairvect[1][1] => pairvect[1][2])
    for p in pairvect[2:end]
        id = StaticDict(id, p[1] => p[2])
    end
    id
end

"""
    # BackedUpImmutableDict{K, V} 
    * Combines a key, not value, immutable hash dictionary with a backup of the original value defaults.
    * For configuration data storage, with a simple restore to default
"""
mutable struct BackedUpImmutableDict{K, V} <: AbstractDict{K,V}
    d::StaticDict
    defaults::Dict{K, V}
end

"""
    Makes a BackedUpImmutableDict from a vector of key, value pairs
"""
BackedUpImmutableDict{K,V}(pairs::Vector{Pair{K,V}}) where V where K =
    BackedUpImmutableDict(StaticDict(pairs), Dict{K,V}(pairs...))

"""
    Makes a BackedUpImmutableDict from a tuple of key, value pairs (varargs style)
"""
BackedUpImmutableDict{K,V}(pairs...) where V where K = BackedUpImmutableDict{K,V}([pairs...])


getindex(dic::BackedUpImmutableDict, k) = dic.d[k]

Base.setindex!(dic::BackedUpImmutableDict{K,V}, v::V, k::K...) where V where K = setindex!(dic.d, v,  k...)

function Base.setindex!(dic::BackedUpImmutableDict{K,V}, v::V, k::K) where V where K
    if haskey(dic.d, k)
        id = Base.ImmutableDict(dic.d, k => v)
        dic.d = id
    else
        throw("Cannot add key $k to ImmutableDict")
    end
end

Base.get(dic::BackedUpImmutableDict, k, v) = get(dic.d, k, v)
Base.get!(dic::BackedUpImmutableDict, k::K, v::V) where V where K = get!(dic.d, k, v)

"""
   # Restore a key's backed up default value.
"""
function restore!(dic, k)
    if haskey(dic.defaults, k)
        dic[k] = (v = dic.defaults[k])
        return v
    end
end

"""
   # Restore all values back to defaults
"""
function restoreall!(dic)
    dic.d = StaticDict(collect(dic.defaults))
end


end # module
