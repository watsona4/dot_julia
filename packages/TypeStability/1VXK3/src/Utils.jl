
export RegexDict

#Miscellanious utility's for users

"""
    RegexDict(::Tuple{Union{Regex, String}, T}...)

Creates a dictionary that uses Regexes as keys and tests against those
when looking up keys.
Symbols can be used as lookup keys, by using their name.
If multiple Regexes match a key, the value associated with any of them may be
returned.
"""
struct RegexDict{T}
    entries::Vector{Tuple{Regex, T}}
end

function RegexDict{T}() where {T}
    RegexDict(Vector{Tuple{Regex, T}}(undef, 0))
end

function RegexDict(pairs::Tuple{Union{Regex, String}, T}...) where {T}
    entries = Vector{Tuple{Regex, T}}(undef, length(pairs))
    for i in 1:length(pairs)
        (key, val) = pairs[i]
        if key isa String
            key = Regex(key)
        end
        entries[i] = (key, val)
    end
    RegexDict(entries)
end

function Base.get(dict::RegexDict, key::Symbol, default)
    get(dict, String(key), default)
end

function Base.get(dict::RegexDict, key::String, default)
    for (entryKey, entryVal) in dict.entries
        if occursin(entryKey, key)
            return entryVal
        end
    end
    return default
end

function Base.getindex(dict::RegexDict, index::Symbol)
    getindex(dict, String(index))
end

function Base.getindex(dict::RegexDict, index::String)
    for (entryKey, entryVal) in dict.entries
        if occursin(entryKey, index)
            return entryVal
        end
    end
    throw(BoundsError(dict, index))
end
