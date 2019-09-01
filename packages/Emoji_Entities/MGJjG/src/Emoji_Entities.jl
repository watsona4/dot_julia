__precompile__()
"""
# Public API (nothing is exported)

* lookupname(str)
* matchchar(char)
* matches(str)
* longestmatches(str)
* completions(str)
"""
module Emoji_Entities

using StrTables

VER = UInt32(1)

struct Emoji_Table{T} <: AbstractEntityTable
    ver::UInt32
    tim::String
    inf::String
    base32::UInt32
    base2c::UInt32
    nam::StrTable{T}
    ind::Vector{UInt16}
    val16::Vector{UInt16}
    ind16::Vector{UInt16}
    val32::Vector{UInt16}
    ind32::Vector{UInt16}
    val2c::StrTable{T}
    ind2c::Vector{UInt16}
    max2c::UInt32
end

function __init__()
    global default =
        Emoji_Table(StrTables.load(joinpath(@__DIR__, "../data", "emoji.dat"))...)
    nothing
end

StrTables._get_val2c(tab::Emoji_Table, val) = val

function StrTables.matches(tab::Emoji_Table, vec::String)
    (isempty(vec)
     ? StrTables._empty_str_vec
     : (length(vec) == 1
        ? matchchar(tab, vec[1])
        : StrTables._get_strings(tab, vec, tab.val2c, tab.ind2c)))
end

StrTables.matches(tab::Emoji_Table, str::AbstractString) = matches(tab, String(str))

function StrTables.longestmatches(tab::Emoji_Table, vec::Vector{T}) where {T}
    isempty(vec) && return StrTables._empty_str_vec
    ch = vec[1]
    len = length(vec)
    len == 1 && return matchchar(tab, ch)
    # Get range that matches the first character, if any
    rng = StrTables.matchfirstrng(tab.val2c, string(ch))
    if !isempty(rng)
        maxlen = min(len, tab.max2c)
        # Truncate vec
        vec = vec[1:maxlen]
        # Need to find longest matching strings
        for l = 2:maxlen
            length(rng) == 1 && break
            prevrng = rng
            rng = StrTables.matchfirstrng(tab.val2c, string(vec[1:l]))
            isempty(rng) && (rng = prevrng; break)
        end
        return tab.nam[tab.ind2c[rng]]
    end
    # Fall through and check only the first character
    matchchar(tab, ch)
end

end # module
