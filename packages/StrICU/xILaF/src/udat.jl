# udat.jl - Wrapper for ICU (International Components for Unicode) library

# Some content of the documentation strings was derived from the ICU header files udat.h
# (Those portions copyright (C) 1996-2015, International Business Machines Corporation and others)

"""
"""
module UDAT
const NONE     = Int32(-1)
const FULL     = Int32(0)
const LONG     = Int32(1)
const MEDIUM   = Int32(2)
const SHORT    = Int32(3)
const RELATIVE = Int32(128)
end # module UDAT

export UDAT, UDateFormat

macro libdat(s)     ; _libicu(s, iculibi18n, "udat_")     ; end

mutable struct UDateFormat
    ptr::Ptr{Cvoid}

    function UDateFormat(tstyle::Integer, dstyle::Integer, tz::Ptr{UInt16}, len)
        err = Ref{UErrorCode}(0)
        p = ccall(@libdat(open), Ptr{Cvoid},
                  (Int32, Int32, Ptr{UInt8}, Ptr{UChar}, Int32,
                   Ptr{UChar}, Int32, Ptr{UErrorCode}),
                  tstyle, dstyle, locale[], tz, len, C_NULL, 0, err)
        FAILURE(err[]) && error("ICU: $(err[]), bad date format")
        self = new(p)
        finalizer(self, close)
        self
    end

    function UDateFormat(pattern::Ptr{UInt16}, patlen, tz::Ptr{UInt16}, tzlen)
        err = Ref{UErrorCode}(0)
        p = ccall(@libdat(open), Ptr{Cvoid},
                  (Int32, Int32, Ptr{UInt8}, Ptr{UChar}, Int32,
                   Ptr{UChar}, Int32, Ptr{UErrorCode}),
                  -2, -2, locale[], tz, tzlen,
                  pattern, patlen, err)
        FAILURE(err[]) && error("ICU: $(err[]), bad date format")
        self = new(p)
        finalizer(self, close)
        self
    end
end

UDateFormat(tstyle::Integer, dstyle::Integer, tz::WordStrings) =
    @preserve tz UDateFormat(tstyle, dstyle, pointer(tz), ncodeunits(tz))
UDateFormat(pattern::WordStrings, tz::WordStrings) =
    @preserve pattern tz UDateFormat(pointer(pattern), ncodeunits(pattern),
                                          pointer(tz), ncodeunits(tz))

UDateFormat(tstyle::Integer, dstyle::Integer, tz::Vector{UInt16}) =
    @preserve tz UDateFormat(tstyle, dstyle, pointer(tz), length(tz))
UDateFormat(pattern::Vector{UInt16}, tz::Vector{UInt16}) =
    @preserve pattern tz UDateFormat(pointer(pattern), length(pattern),
                                          pointer(tz), length(tz))

UDateFormat(pattern::AbstractString, tz::AbstractString) =
    UDateFormat(cvt_utf16(pattern), cvt_utf16(tz))

UDateFormat(tstyle::Integer, dstyle::Integer, tz::AbstractString) =
    UDateFormat(tstyle, dstyle, cvt_utf16(tz))

close(df::UDateFormat) =
    df.ptr == C_NULL || (ccall(@libdat(close), Cvoid, (Ptr{Cvoid},), df.ptr) ; df.ptr = C_NULL)

function format(df::UDateFormat, millis::Float64)
    err = Ref{UErrorCode}(0)
    buflen = 64
    buf, pnt = _allocate(UInt16, buflen)
    len = ccall(@libdat(format), Int32,
                (Ptr{Cvoid}, Float64, Ptr{UChar}, Int32, Ptr{Cvoid}, Ptr{UErrorCode}),
                df.ptr, millis, pnt, buflen, C_NULL, err)
    FAILURE(err[]) && error("ICU: $(err[]), failed to format time")
    Str(UTF16CSE, buf[1:len])
end

parse(df::UDateFormat, s::AbstractString) = parse(df, cvt_utf16(s))
parse(df::UDateFormat, s::Vector{UInt16}) = @preserve s parse(df, pointer(s), length(s))
parse(df::UDateFormat, s::WordStrings)    = @preserve s parse(df, pointer(s), ncodeunits(s))

function parse(df::UDateFormat, s16::Ptr{UInt16}, slen)
    err = Ref{UErrorCode}(0)
    ret = ccall(@libdat(parse), Float64,
                (Ptr{Cvoid}, Ptr{UChar}, Int32, Ptr{Int32}, Ptr{UErrorCode}),
                df.ptr, s16, slen, C_NULL, err)
    FAILURE(err[]) && error("ICU: $(err[]), failed to parse string")
    ret
end
