# ucasemap.jl - Wrapper for ICU (International Components for Unicode) library

# Some content of the documentation strings was derived from the ICU header files ucasemap.h
# (Those portions copyright (C) 1996-2015, International Business Machines Corporation and others)

"""
   Unicode case mapping functions using a UCaseMap service object.

   The service object takes care of memory allocations, data loading, and setup for the attributes, as usual.

   Currently, the functionality provided here does not overlap with uchar.h and ustring.h, except for ucasemap_toTitle().
"""
module ucasemap end

macro libcasemap(s) ; _libicu(s, iculib,     "ucasemap_") ; end

const casemap  = Ptr{Cvoid}[C_NULL]
const collator = [UCollator()]

for f in (:ToLower, :ToUpper, :FoldCase, :ToTitle)
    lf = Symbol(lowercase(string(f)))
    ff = Symbol(string("utf8", f))
    uf = Symbol(string('_',lf))
    @eval begin
        ($uf)(dest, destsiz, src, srclen, err) =
            ccall(@libcasemap($ff), Int32,
                  (Ptr{Cvoid}, Ptr{UInt8}, Int32, Ptr{UInt8}, Int32, Ptr{UErrorCode}),
                  casemap[], dest, destsiz, src, srclen, err)
        function ($lf)(str::ByteStr)
            dstlen = srclen = sizeof(str)
            dest = _allocate(dstlen)
            err = Ref{UErrorCode}(0)
            siz = ($uf)(dest, dstlen, str, srclen, err)
            # Retry with large enough buffer if got buffer overflow
            if err[] == U_BUFFER_OVERFLOW_ERROR
                err[] = 0
                dstlen = siz
                dest = _allocate(dstlen)
                siz = ($uf)(dest, dstlen, str, srclen, err)
            end
            FAILURE(err[]) && error("failed to map case: $(err[])")
            siz != dstlen ? cvt_utf8(dest[1:siz]) : cvt_utf8(dest)
        end
    end
end

get_break_iterator() = ccall(@libcasemap(getBreakIterator), Ptr{Cvoid}, (Ptr{Cvoid},), casemap[])

function set_locale!(loc::ASCIIStr)
    if casemap[] != C_NULL
        ccall(@libcasemap(close), Cvoid, (Ptr{Cvoid},), casemap[])
        casemap[] = C_NULL
    end
    collator[] = UCollator(loc)
    err = Ref{UErrorCode}(0)
    casemap[] = (loc == ""
                 ? ccall(@libcasemap(open), Ptr{Cvoid}, (Ptr{UInt8}, Int32, Ptr{UErrorCode}),
                         C_NULL, 0, err)
                 : ccall(@libcasemap(open), Ptr{Cvoid}, (Cstring, Int32, Ptr{UErrorCode}),
                         loc, 0, err))
    FAILURE(err[]) && error("could not set casemap $(err[])")
    locale[] = loc
end

set_locale!(loc::AbstractString) = set_locale!(ASCIIStr(loc))
