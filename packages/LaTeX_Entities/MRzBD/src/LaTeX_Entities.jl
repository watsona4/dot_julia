# License is MIT: https://github.com/JuliaString/LaTeX_Entities/LICENSE.md

__precompile__()

"""
# Public API (nothing is exported)

* lookupname(str)
* matchchar(char)
* matches(str)
* longestmatches(str)
* completions(str)
"""
module LaTeX_Entities

using StrTables

VER = UInt32(1)

struct LaTeX_Table{T} <: AbstractEntityTable
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
        LaTeX_Table(StrTables.load(joinpath(@__DIR__, "../data", "latex.dat"))...)
    nothing
end

end # module LaTeX_Entities
