# This file includes code originally part of Julia.n
# Licensed under MIT License, see LICENSE.md

# The plan is to rewrite all of the functionality to not use the utf8proc library,
# and to use tables loaded up on initialization, as with StringLiterals.jl

# Currently, this depends on the following C calls:
# utf8proc_errmsg
# utf8proc_decompose
# utf8proc_reencode

############################################################################

function utf8proc_map(::Type{T}, str::MaybeSub{T}, options::Integer) where {T<:Str}
    nwords = ccall(:utf8proc_decompose, Int, (Ptr{UInt8}, Int, Ptr{UInt8}, Int, Cint),
                   str, sizeof(str), C_NULL, 0, options)
    nwords < 0 && utf8proc_error(nwords)
    buffer = Base.StringVector(nwords*4)
    nwords = ccall(:utf8proc_decompose, Int, (Ptr{UInt8}, Int, Ptr{UInt8}, Int, Cint),
                   str, sizeof(str), buffer, nwords, options)
    nwords < 0 && utf8proc_error(nwords)
    nbytes = ccall(:utf8proc_reencode, Int, (Ptr{UInt8}, Int, Cint), buffer, nwords, options)
    nbytes < 0 && utf8proc_error(nbytes)
    Str(cse(T), String(resize!(buffer, nbytes)))
end

utf8proc_map(str::MaybeSub{T}, options::Integer) where {T<:Str} =
    utf8proc_map(T, convert(UTF8Str, str), options)
utf8proc_map(str::MaybeSub{<:Str{UTF8CSE}}, options::Integer) =
    utf8proc_map(UTF8Str, str, options)

############################################################################

function _normalize(::Type{T}, str::AbstractString;
                   stable::Bool      = false,
                   compat::Bool      = false,
                   compose::Bool     = true,
                   decompose::Bool   = false,
                   stripignore::Bool = false,
                   rejectna::Bool    = false,
                   newline2ls::Bool  = false,
                   newline2ps::Bool  = false,
                   newline2lf::Bool  = false,
                   stripcc::Bool     = false,
                   casefold::Bool    = false,
                   lump::Bool        = false,
                   stripmark::Bool   = false,
                   ) where {T<:Str}
    (compose & decompose) && strerror(StrErrors.DECOMPOSE_COMPOSE)
    (!(compat | stripmark) & (compat | stripmark)) && strerror(StrErrors.COMPAT_STRIPMARK)
    newline2ls + newline2ps + newline2lf > 1 && strerror(StrErrors.NL_CONVERSION)
    flags =
        ifelse(stable,      Uni.STABLE, 0) |
        ifelse(compat,      Uni.COMPAT, 0) |
        ifelse(decompose,   Uni.DECOMPOSE, 0) |
        ifelse(compose,     Uni.COMPOSE, 0) |
        ifelse(stripignore, Uni.IGNORE, 0) |
        ifelse(rejectna,    Uni.REJECTNA, 0) |
        ifelse(newline2ls,  Uni.NLF2LS, 0) |
        ifelse(newline2ps,  Uni.NLF2PS, 0) |
        ifelse(newline2lf,  Uni.NLF2LF, 0) |
        ifelse(stripcc,     Uni.STRIPCC, 0) |
        ifelse(casefold,    Uni.CASEFOLD, 0) |
        ifelse(lump,        Uni.LUMP, 0) |
        ifelse(stripmark,   Uni.STRIPMARK, 0)
    T(utf8proc_map(str, flags))
end

normalize(str::T, options::Integer) where {T<:Str} = _normalize(T, UTF8Str(str), options)
normalize(str::Str{UTF8CSE}, options::Integer) = _normalize(UTF8Str, str, options)

normalize(str::Str, nf::Symbol) =
    utf8proc_map(str, nf == :NFC ? (Uni.STABLE | Uni.COMPOSE) :
                 nf == :NFD ? (Uni.STABLE | Uni.DECOMPOSE) :
                 nf == :NFKC ? (Uni.STABLE | Uni.COMPOSE | Uni.COMPAT) :
                 nf == :NFKD ? (Uni.STABLE | Uni.DECOMPOSE | Uni.COMPAT) :
                 strerror(StrErrors.NORMALIZE, nf))
