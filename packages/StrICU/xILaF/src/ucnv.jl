# ucnv.jl - Wrapper for ICU (International Components for Unicode) library

# Some content of the documentation strings was derived from the ICU header files ucnv.h
# (Those portions copyright (C) 1996-2015, International Business Machines Corporation and others)

"""
"""
module ucnv end

macro libcnv(s)     ; _libicu(s, iculibi18n, "ucnv_")     ; end

export UConverter

mutable struct UConverter
    p::Ptr{Cvoid}

    function UConverter(name::ASCIIStr)
        err = Ref{UErrorCode}(0)
        p = ccall(@libcnv(open), Ptr{Cvoid}, (Cstring, Ptr{UErrorCode}), name, err)
        SUCCESS(err[]) || error("ICU: $(err[]), could not open converter ", name)
        self = new(p)
        finalizer(self, close)
        self
    end
end

close(c::UConverter) =
    c.p == C_NULL || (ccall(@libcnv(close), Cvoid, (Ptr{Cvoid},), c.p); c.p = C_NULL)

struct UConverterPivot
    buf::Vector{UCS2Chr}
    pos::Vector{Ptr{UCS2Chr}}

    function UConverterPivot(n::Int)
        buf = create_vector(UCS2Chr, n)
        p = pointer(buf)
        new(buf, [p,p])
    end
end

function convert!(dstcnv::UConverter, srccnv::UConverter,
                  dst::IOBuffer, src::IOBuffer, pivot::UConverterPivot,
                  reset::Bool=false, flush::Bool=true)
    @preserve dst src pivot begin
        p = Ptr{UInt8}[pointer(dst.data, position(dst)+1),
                       pointer(src.data, position(src)+1)]
        p0 = copy(p)
        err = Ref{UErrorCode}(0)
        ccall(@libcnv(convertEx), Cvoid,
              (Ptr{Cvoid}, Ptr{Cvoid},
               Ptr{Ptr{UInt8}}, Ptr{UInt8}, Ptr{Ptr{UInt8}}, Ptr{UInt8},
               Ptr{UCS2Chr}, Ptr{Ptr{UCS2Chr}}, Ptr{Ptr{UCS2Chr}}, Ptr{UCS2Chr},
               UBool, UBool, Ptr{UErrorCode}),
              dstcnv.p, srccnv.p,
              pointer(p, 1), pointer(dst.data, length(dst.data)+1),
              pointer(p, 2), pointer(src.data, src.size+1),
              pointer(pivot.buf, 1),
              pointer(pivot.pos, 1),
              pointer(pivot.pos, 2),
              pointer(pivot.buf, length(pivot.buf)+1),
              reset, flush, err)
        dst.size += p[1] - p0[1]
        dst.ptr += p[1] - p0[1]
        src.ptr += p[2] - p0[2]
    end
    err[] == U_BUFFER_OVERFLOW_ERROR && return true
    @assert SUCCESS(err[])
    false
end

function to_uchars(cnv::UConverter, src::Vector{UInt8})
    @preserve src begin
        srclen = length(src)
        dstlen = 2 * srclen + 1
        buf, pnt = _allocate(UInt16, dstlen)
        err = Ref{UErrorCode}(0)
        n = ccall(@libcnv(toUChars), Int32,
                  (Ptr{Cvoid}, Ptr{UCS2Chr}, Int32, Ptr{UInt8}, Int32, Ptr{UErrorCode}),
                  cnv.p, pnt, dstlen, src, srclen, err)
        SUCCESS(err[]) || error("ICU: $(err[]), could not convert string")
        Str(UTF16CSE, u[1:n])
    end
end

"""
    Determines if the converter contains ambiguous mappings of the same character or not.

    Arguments:
    cnv - the converter to be tested

    Return `true` if the converter contains ambiguous mapping of the same character, `false` otherwise.
"""
function isambiguous(cnv::UConverter)
    err = Ref{UErrorCode}(0)
    v = ccall(@libcnv(isAmbiguous), Bool, (Ptr{Cvoid}, Ptr{UErrorCode}), cnv.p, err)
    SUCCESS(err[]) || error("ICU: internal error $(err[]) in ucnv_isFixedWidth")
    v
end

"""
    Detects Unicode signature byte sequences at the start of the byte stream
    and returns the charset nameof the indicated Unicode charset.
    NULL is returned when no Unicode signature is recognized.
    The number of bytes in the signature is output as well.

    The caller can ucnv_open() a converter using the charset name.
    The first code unit (UCS2Chr) from the start of the stream will be U+FEFF
    (the Unicode BOM/signature character) and can usually be ignored.

    For most Unicode charsets it is also possible to ignore the indicated
    number of initial stream bytes and start converting after them.
    However, there are stateful Unicode charsets (UTF-7 and BOCU-1) for which
    this will not work. Therefore, it is best to ignore the first output UCS2Chr
    instead of the input signature bytes.

    Arguments:
    source - The source string in which the signature should be detected.

    Returns: the name of the encoding detected, and the length of the signature
"""
function detect_unicode_signature(src::Vector{UInt8})
    err = Ref{UErrorCode}(0)
    sig = Ref{Int32}(0)
    p = ccall(@libcnv(detectUnicodeSignature), Ptr{UInt8},
              (Ptr{UInt8}, Int32, Ptr{Int32}, Ptr{UErrorCode}),
              src, sizeof(src), sig, err)
    SUCCESS(err[]) || error("ICU: internal error $(err[]) in ucnv_detectUnicodeSignature")
    return (p == C_NULL ? UTF8Str() : UTF8Str(p), sig[])
end

"""
    Returns the number of chars held in the converter's internal state
    because more input is needed for completing the conversion. This function is
    useful for mapping semantics of ICU's converter interface to those of iconv,
    and this information is not needed for normal conversion.

    Arguments:
    cnv - The converter in which the input is held as internal state

    Returns: the number of chars in the state or -1 if an error is encountered.
"""
function from_ucount_pending(cnv::UConverter)
    err = Ref{UErrorCode}(0)
    v = ccall(@libcnv(toUCountPending), Int32, (Ptr{Cvoid}, Ptr{UErrorCode}), cnv.p, err)
    SUCCESS(err[]) || error("ICU: internal error $(err[]) in ucnv_fromUCountPending")
    v
end

"""
    Returns the number of chars held in the converter's internal state
    because more input is needed for completing the conversion. This function is
    useful for mapping semantics of ICU's converter interface to those of iconv,
    and this information is not needed for normal conversion.

    Arguments:
    cnv - The converter in which the input is held as internal state

    Returns: the number of chars in the state or -1 if an error is encountered.
"""
function to_ucount_pending(cnv::UConverter)
    err = Ref{UErrorCode}(0)
    v = ccall(@libcnv(toUCountPending), Int32, (Ptr{Cvoid}, Ptr{UErrorCode}), cnv.p, err)
    SUCCESS(err[]) || error("ICU: internal error $(err[]) in ucnv_toUCountPending")
    v
end

"""
    Returns whether or not the charset of the converter has a fixed number of bytes
    per charset character.
    An example of this are converters that are of the type UCNV_SBCS or UCNV_DBCS.
    Another example is UTF-32 which is always 4 bytes per character.
    A Unicode code point may be represented by more than one UTF-8 or UTF-16 code unit
    but a UTF-32 converter encodes each code point with 4 bytes.
    Note: This method is not intended to be used to determine whether the charset has a
    fixed ratio of bytes to Unicode codes <i>units</i> for any particular Unicode encoding form.
    `false` is returned with the UErrorCode if error occurs or cnv is NULL.

    Arguments:
    cnv       The converter to be tested
    status    ICU error code in/out paramter

    Returns: `true` if the converter is fixed-width
"""
function is_fixed_width(cnv::UConverter)
    err = Ref{UErrorCode}(0)
    v = ccall(@libcnv(isFixedWidth), Bool, (Ptr{Cvoid}, Ptr{UErrorCode}), cnv.p, err)
    SUCCESS(err[]) || error("ICU: internal error $(err[]) in ucnv_isFixedWidth")
    v
end



