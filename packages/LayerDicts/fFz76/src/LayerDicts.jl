module LayerDicts

export LayerDict

struct LayerDict{K, V} <: AbstractDict{K, V}
    dicts::Vector{<:AbstractDict}
end

function LayerDict(dicts::Tuple{Vararg{AbstractDict{K, V}}}) where {K, V}
    return LayerDict{K, V}(collect(dicts))
end

function LayerDict(dicts::AbstractVector{<:AbstractDict{K, V}}) where {K, V}
    return LayerDict{K, V}(dicts)
end

function LayerDict(dicts::AbstractVector{<:AbstractDict})
    K, V = _kv_types(dicts)

    return LayerDict{K, V}(dicts)
end

function LayerDict(dicts::Tuple{Vararg{AbstractDict}})
    K, V = _kv_types(dicts)

    return LayerDict{K, V}(collect(dicts))
end

LayerDict(::Tuple{}) = LayerDict{Any, Any}(AbstractDict[])

LayerDict(dicts::AbstractDict...) = LayerDict(dicts)

function _kv_types(dicts)
    if isempty(dicts)
        return (Any, Any)
    end

    first_dict = first(dicts)
    K = keytype(first_dict)
    V = valtype(first_dict)

    for dict in dicts[2:end]
        if K === Any && V === Any
            break
        end

        K = typejoin(K, keytype(dict))
        V = typejoin(V, valtype(dict))
    end

    return (K, V)
end

function Base.keys(ld::LayerDict{K}) where K
    key_set = Set{K}()

    for dict in ld.dicts
        union!(key_set, keys(dict))
    end

    return key_set
end

Base.length(ld::LayerDict) = length(keys(ld))

function Base.iterate(ld::LayerDict, state=(keys(ld),))
    ld_keys = first(state)
    key_state = Base.tail(state)

    @assert length(key_state) == 0 || length(key_state) == 1

    iter = iterate(ld_keys, key_state...)

    iter === nothing && return nothing

    key, new_key_state = iter

    return (key => ld[key]), (ld_keys, new_key_state)
end

function Base.getindex(ld::LayerDict{K, V}, key) where {K, V}
    for dict in ld.dicts
        if haskey(dict, key)
            return dict[key]::V
        end
    end

    throw(KeyError(key))
end

function Base.haskey(ld::LayerDict, key)
    for dict in ld.dicts
        if haskey(dict, key)
            return true
        end
    end

    return false
end

function Base.get(ld::LayerDict{K, V}, key, default::D) where {K, V, D}
    ReturnType = typejoin(V, D)

    for dict in ld.dicts
        if haskey(dict, key)
            return dict[key]::ReturnType
        end
    end

    return default
end

function Base.get(f::Base.Callable, ld::LayerDict, key)
    for dict in ld.dicts
        if haskey(dict, key)
            return dict[key]
        end
    end

    return f()
end

end
