####
#### Manipulating keys (tuples of Symbol)
####
#### These used as of type parameters, so care is taken to allow @pure functions.
####

"""
Type for keys, used internally.
"""
const Key = Symbol

const Keys = Tuple{Vararg{Symbol}}

"""
$(SIGNATURES)

Check if a `key` is in `itr`.
"""
Base.@pure function key_in(key::Key, keys::Keys)
    for k in keys
        key ≡ k && return true
    end
    false
end


Base.@pure function key_issubset(a::Keys, b::Keys)
    for k in a
        key_in(k, b) || return false
    end
    true
end

Base.@pure function key_setdiff(a::Keys, b::Keys)
    kept = Symbol[]
    for k in a
        key_in(k, b) || push!(kept, k)
    end
    (kept..., )
end
