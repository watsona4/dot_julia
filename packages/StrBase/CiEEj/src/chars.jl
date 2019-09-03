#=
Chr support

Copyright 2017-2018 Gandalf Software, Inc., Scott P. Jones
Licensed under MIT License, see LICENSE.md
In part based on code for Char in Julia
=#

"""Type of codeunits"""
codeunit(::Type{UniStr})    = UInt32 # Note, the real type could be UInt8, UInt16, or UInt32
codeunit(::Type{<:Str{C}}) where {C<:CSE} = codeunit(C)

codeunit(::MaybeSub{S}) where {S<:Str} = codeunit(S)
codeunit(::Type{<:MaybeSub{S}}) where {S<:Str} = codeunit(S)

eltype(::Type{<:Str{BinaryCSE}}) = UInt8

eltype(::Type{UniStr})                = UTF32Chr
eltype(::Type{<:Str{Text1CSE}})       = Text1Chr
eltype(::Type{<:Str{Text2CSE}})       = Text2Chr
eltype(::Type{<:Str{Text4CSE}})       = Text4Chr
eltype(::Type{<:Str{ASCIICSE}})       = ASCIIChr
eltype(::Type{<:Str{LatinCSE}})       = LatinChr
eltype(::Type{<:Str{_LatinCSE}})      = _LatinChr
eltype(::Type{<:Str{<:Union{UCS2CSE, _UCS2CSE}}}) = UCS2Chr
eltype(::Type{<:Str{<:Union{UTF8CSE, UTF16CSE, UTF32_CSEs}}}) = UTF32Chr

get_codeunit(dat, pos) = codeunit(dat, pos)
get_codeunit(pnt::Ptr{<:CodeUnitTypes}, pos) = unsafe_load(pnt, pos)
get_codeunit(dat::AbstractArray{<:CodeUnitTypes}, pos) = dat[pos]
get_codeunit(str::MaybeSub{<:Str}, pos::Integer) = @preserve str get_codeunit(pointer(str), pos)

get_codeunit(dat) = get_codeunit(dat, 1)
get_codeunit(pnt::Ptr{<:CodeUnitTypes}) = unsafe_load(pnt)

codeunit(str::Str, pos::Integer) = get_codeunit(str, pos)

set_codeunit!(pnt::Ptr{<:CodeUnitTypes}, pos, ch) = unsafe_store!(pnt, ch, pos)
set_codeunit!(dat::AbstractArray{<:CodeUnitTypes}, pos, ch) = (dat[pos] = ch)
set_codeunit!(dat::String, pos, ch) = unsafe_store!(pointer(dat), pos, ch)

set_codeunit!(pnt::Ptr{<:CodeUnitTypes}, ch) = unsafe_store!(pnt, ch)
set_codeunit!(dat::AbstractArray{<:CodeUnitTypes}, ch) = (dat[1] = ch)
set_codeunit!(dat::String, ch) = set_codeunit!(dat, 1, ch)
