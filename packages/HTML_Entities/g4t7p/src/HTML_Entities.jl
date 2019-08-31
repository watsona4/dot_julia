__precompile__()
"""
# Public API (nothing is exported)

* lookupname(str)
* matches(str)
* longestmatches(str)
* completions(str)
"""
module HTML_Entities
using StrTables

VER = UInt32(1)

struct HTML_Table{T} <: AbstractEntityTable
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
    val2c::Vector{UInt32}
    ind2c::Vector{UInt16}
end

function __init__()
    global default =
        HTML_Table(StrTables.load(joinpath(@__DIR__, "../data", "html.dat"))...)
    nothing
end
end # module HTML_Entities
