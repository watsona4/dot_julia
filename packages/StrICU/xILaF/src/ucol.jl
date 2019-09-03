# ucol.jl - Wrapper for ICU (International Components for Unicode) library

# Some content of the documentation strings was derived from the ICU header files ucol.h
# (Those portions copyright (C) 1996-2015, International Business Machines Corporation and others)

"""
   Collator 

   The C API for Collator performs locale-sensitive string comparison. You use this service to build
   searching and sorting routines for natural language text.
   <p>
   For more information about the collation service see 
   <a href="http://userguide.icu-project.org/collation">the User Guide</a>.
   <p>
   Collation service provides correct sorting orders for most locales supported in ICU. 
   If specific data for a locale is not available, the orders eventually falls back to the
    <a href="http://www.unicode.org/reports/tr35/tr35-collation.html#Root_Collation">CLDR root sort order</a>.
   <p>
   Sort ordering may be customized by providing your own set of rules. For more on this subject see the
   <a href="http://userguide.icu-project.org/collation/customization">
   Collation Customization</a> section of the User Guide.
"""
module ucol end

macro libcol(s)     ; _libicu(s, iculibi18n, "ucol_")     ; end

mutable struct UCollator
    p::Ptr{Cvoid}

    UCollator() = new(C_NULL)
    function UCollator(loc)
        p = _ucol_open(loc)
        self = new(p)
        finalizer(self, close)
        self
    end
end

function _ucol_open(loc::ASCIIStr)
    err = Ref{UErrorCode}(0)
    p = (loc == ""
         ? ccall(@libcol(open), Ptr{Cvoid}, (Ptr{UInt8}, Ptr{UErrorCode}), C_NULL, err)
         : ccall(@libcol(open), Ptr{Cvoid}, (Cstring, Ptr{UErrorCode}), loc, err))
    SUCCESS(err[]) || error("ICU: $(err[]), could not open collator for locale ", loc)
    p
end
_ucol_open(loc::AbstractString) = _ucol_open(ASCIIStr(loc))

close(c::UCollator) =
    c.p == C_NULL || (ccall(@libcol(close), Cvoid, (Ptr{Cvoid},), c.p) ; c.p = C_NULL)

"""
   strcoll(c::UCollator, a, b)

   Compare two strings.

   The strings will be compared using the options already specified.

   Arguments:
    coll   The UCollator containing the comparison rules.
    source The source string.
    target The target string.

   Returns: -1, 0, or 1
"""
function strcoll end

strcoll(c::UCollator, a::ByteStr, b::ByteStr) = strcoll(c, Vector{UInt8}(a), Vector{UInt8}(b))
function strcoll(c::UCollator, a::Vector{UInt8}, b::Vector{UInt8})
    err = Ref{UErrorCode}(0)
    o = ccall(@libcol(strcollUTF8), Int32,
              (Ptr{Cvoid}, Ptr{UInt8}, Int32, Ptr{UInt8}, Int32, Ptr{UErrorCode}),
              c.p, a, sizeof(a), b, sizeof(b), err)
    @assert SUCCESS(err[])
    o
end

strcoll(c::UCollator, a::UTF16Str, b::UTF16Str) =
    strcoll(c, Vector{UInt16}(a), Vector{UInt16}(b))
function strcoll(c::UCollator, a::Vector{UInt16}, b::Vector{UInt16})
    err = Ref{UErrorCode}(0)
    o = ccall(@libcol(strcoll), Int32,
              (Ptr{Cvoid}, Ptr{UChar}, Int32, Ptr{UChar}, Int32, Ptr{UErrorCode}),
              c.p, a, length(a), b, length(b), err)
    @assert SUCCESS(err[])
    o
end
strcoll(c::UCollator, a::UTF16Str, b::AbstractString) = strcoll(c, a, cvt_utf16(b))
strcoll(c::UCollator, a::AbstractString, b::UTF16Str) = strcoll(c, cvt_utf16(a), b)

strcoll(c::UCollator, a::ByteStr, b::UTF16Str) = strcoll(c, cvt_utf16(a), b)
strcoll(c::UCollator, a::UTF16Str, b::ByteStr) = strcoll(c, a, cvt_utf16(b))
