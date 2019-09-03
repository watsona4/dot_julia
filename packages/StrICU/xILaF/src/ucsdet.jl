# ucsdet.jl - Wrapper for ICU (International Components for Unicode) library

# Some content of the documentation strings was derived from the ICU header files ucsdet.h
# (Those portions copyright (C) 1996-2015, International Business Machines Corporation and others)

"""
   Charset Detection API

   This API provides a facility for detecting the charset or encoding of character data in an unknown text format.
   The input data can be from an array of bytes.

   Character set detection is at best an imprecise operation.  The detection process will attempt to identify the
   charset that best matches the characteristics of the byte data, but the process is partly statistical in nature,
   and the results can not be guaranteed to always be correct.

   For best accuracy in charset detection, the input data should be primarily in a single language, and a minimum of
   a few hundred bytes worth of plain text in the language are needed.  The detection process will attempt to
   ignore html or xml style markup that could otherwise obscure the content.
"""
module ucsdet end

macro libucsdet(s)  ; _libicu(s, iculibi18n, "ucsdet_")   ; end

export UCharsetDetector

const _empty_vec8 = UInt8[]

mutable struct UCharsetDetector
    p::Ptr{Cvoid}
    s

    function UCharsetDetector()
        err = Ref{UErrorCode}(0)
        p = ccall(@libucsdet(open), Ptr{Cvoid}, (Ptr{UErrorCode},), err)
        SUCCESS(err[]) || error("ICU: $(err[]), could not open charset detector")
        self = new(p, _empty_vec8)
        finalizer(self, close)
        self
    end
end
close(c::UCharsetDetector) =
    c.p == C_NULL || (ccall(@libucsdet(close), Cvoid, (Ptr{Cvoid},), c.p); c.p = C_NULL)

"""
   Set the input byte data whose charset is to detected.

   Ownership of the input text byte array remains with the caller.
   The input string must not be altered or deleted until the charset detector is either closed or reset
   to refer to different input text.

   Arguments:
   csd   the charset detector to be used.
   s     the input text of unknown encoding.
"""
function set!(csd::UCharsetDetector, s, p::Ptr{UInt8}, len)
    csd.s = s
    err = Ref{UErrorCode}(0)
    ccall(@libucsdet(setText), Cvoid,
          (Ptr{Cvoid}, Ptr{UInt8}, Int32, Ptr{UErrorCode}), csd.p, p, len, err)
    SUCCESS(err[]) || error("ICU: $(err[]), could not set charset detector text")
    nothing
end
set!(csd::UCharsetDetector, s::Str) =
    @preserve s set!(csd, s, reinterpret(Ptr{UInt8}, pointer(s)), ncodeunits(s))
set!(csd::UCharsetDetector, s::Vector{UInt8}) =
    @preserve s set!(csd, s, pointer(s), length(s))
set!(csd::UCharsetDetector, s::CodeUnits) = set!(csd, Vector{UInt8}(s))
set!(csd::UCharsetDetector, s::AbstractString) = set!(csd, codeunits(s))

"""
   Set the declared encoding for charset detection.
   The declared encoding of an input text is an encoding obtained by the user from an http header or xml
   declaration or similar source that can be provided as an additional hint to the charset detector.

   How and whether the declared encoding will be used during the detection process is TBD.

   Arguments:
   csd      the charset detector to be used.
   encoding encoding for the current data obtained from a header or declaration or other source outside
            of the byte data itself.
"""
function set_declared_encoding!(csd::UCharsetDetector, s::Ptr{UInt8}, len)
    err = Ref{UErrorCode}(0)
    ccall(@libucsdet(setDeclaredEncoding), Cvoid,
          (Ptr{Cvoid},Ptr{UInt8},Int32,Ptr{UErrorCode}), csd.p, s, len, err)
    SUCCESS(err[]) || error("ICU: $(err[]), could not set charset detector declared encoding")
    nothing
end
set_declared_encoding!(csd::UCharsetDetector, s::T) where {T<:Str} =
    @preserve s set_declared_encoding(csd, reinterpret(Ptr{UInt8}, pointer(s)), sizeof(s))
set_declared_encoding!(csd::UCharsetDetector, s::AbstractString) =
    @preserve s set_declared_encoding(csd, pointer(s), sizeof(s))
set_declared_encoding!(csd::UCharsetDetector, s::Vector{T}) where {T<:Union{UInt8,UInt16,UInt32}} =
    @preserve s set_declared_encoding(csd, pointer(s), sizeof(s))

"""
   Opaque structure representing a match that was identified from a charset detection operation.
"""
mutable struct UCharsetMatch
    p::Ptr{Cvoid}
    # This is needed to keep the UCharsetDetector from being GCed until after all dependent UCharsetMatch's are GCed
    ucd::UCharsetDetector
end

"""
   Return the charset that best matches the supplied input data.

   Note though, that because the detection only looks at the start of the input data, there is a possibility
   that the returned charset will fail to handle the full set of input data.

   The returned UCharsetMatch object is owned by the UCharsetDetector.
   It will remain valid until the detector input is reset, or until the detector is closed.

   The function will fail if
   <ul>
     <li>no charset appears to match the data.</li>
     <li>no input text has been provided</li>
   </ul>

   Arguments:
   csd      the charset detector to be used.
   status   any error conditions are reported back in this variable.

   Returns: a UCharsetMatch representing the best matching charset, or nothing if no charset matches the byte data.
"""
function detect(csd::UCharsetDetector)
    err = Ref{UErrorCode}(0)
    p = ccall(@libucsdet(detect), Ptr{Cvoid}, (Ptr{Cvoid},Ptr{UErrorCode}), csd.p, err)
    SUCCESS(err[]) || error("ICU: $(err[]), could not detect encoding")
    p != C_NULL ? UCharsetMatch(p, csd) : nothing
end

"""
   Find all charset matches that appear to be consistent with the input, returning an array of results.

   The results are ordered with the best quality match first.

   Because the detection only looks at a limited amount of the input byte data, some of the returned charsets may fail
   to handle the all of input data.

   The returned UCharsetMatch objects are owned by the UCharsetDetector.
   They will remain valid until the detector is closed or modified
   
   Return an error if 
   <ul>
    <li>no charsets appear to match the input data.</li>
    <li>no input text has been provided</li>
   </ul>

   Arguments:
   ucsd          the charset detector to be used.
   matches       Found pointer to a variable that will be set to the number of charsets identified that
                 are consistent with athe input data.  Output only.
   status        any error conditions are reported back in this variable.

   Returns:      A pointer to an array of pointers to UCharSetMatch objects.
                 This array, and the UCharSetMatch instances to which it refers, are owned by the UCharsetDetector,
                 and will remain valid until the detector is closed or modified.
"""
function detectall(csd::UCharsetDetector)
    err = Ref{UErrorCode}(0)
    n = Ref{Int32}(0)
    p = ccall(@libucsdet(detectAll), Ptr{Ptr{Cvoid}},
              (Ptr{Cvoid},Ptr{Int32},Ptr{UErrorCode}), csd.p, n, err)
    SUCCESS(err[]) || error("ICU: $(err[]), could not detect encoding")
    n[] > 0 || return Vector{UCharsetMatch}()

    [UCharsetMatch(x) for x in pointer_to_array(p, int(n[]))]
end

"""
   Get the name of the charset represented by a UCharsetMatch.
 
   The storage for the returned name string is owned by the UCharsetMatch, and will remain valid
   while the UCharsetMatch is valid.

   The name returned is suitable for use with the ICU conversion APIs.

   Arguments:
   ucsm     The charset match object.
   status   Any error conditions are reported back in this variable.

   Returns: The name of the matching charset.
"""
function get_name(csmatch::UCharsetMatch)
    csmatch.p != C_NULL || throw(UndefRefError())
    err = Ref{UErrorCode}(0)
    name = ccall(@libucsdet(getName), Ptr{UInt8}, (Ptr{Cvoid},Ptr{UErrorCode}), csmatch.p, err)
    SUCCESS(err[]) || error("ICU: $(err[]), could not get name of matching encoding")
    unsafe_string(name)
end

"""
   Get a confidence number for the quality of the match of the byte data with the charset.
   Confidence numbers range from zero to 100, with 100 representing complete confidence and zero
   representing no confidence.

   The confidence values are somewhat arbitrary.  They define an an ordering within the results for any
   single detection operation but are not generally comparable between the results for different input.

   A confidence value of ten does have a general meaning - it is used for charsets that can represent the
   input data, but for which there is no other indication that suggests that the charset is the correct one.
   Pure 7 bit ASCII data, for example, is compatible with a great many charsets, most of which will appear as
   possible matches with a confidence of 10.

   Arguments:
   ucsm     The charset match object.
   status   Any error conditions are reported back in this variable.

   Returns: A confidence number for the charset match.
"""
function get_confidence(csmatch::UCharsetMatch)
    csmatch.p != C_NULL || throw(UndefRefError())
    err = Ref{UErrorCode}(0)
    confidence = ccall(@libucsdet(getConfidence), Int32,
                       (Ptr{Cvoid},Ptr{UErrorCode}), csmatch.p, err)
    SUCCESS(err[]) || error("ICU: $(err[]), could not get confidence")
    Int(confidence)
end

"""
   Get the RFC 3066 code for the language of the input data.

   The Charset Detection service is intended primarily for detecting charsets, not language.
   For some, but not all, charsets, a language is identified as a byproduct of the detection process,
   and that is what is returned by this function.

   CAUTION:
      1.  Language information is not available for input data encoded in all charsets. In particular,
          no language is identified for UTF-8 input data.
      2.  Closely related languages may sometimes be confused.

   If more accurate language detection is required, a linguistic analysis package should be used.

   The storage for the returned name string is owned by the UCharsetMatch, and will remain valid
   while the UCharsetMatch is valid.

   Arguments:
   ucsm    The charset match object.
   status  Any error conditions are reported back in this variable.

   Returns:
   The RFC 3066 code for the language of the input data, or an empty string if the language could not be determined.
"""
function get_language(csmatch::UCharsetMatch)
    csmatch.p != C_NULL || throw(UndefRefError())
    err = Ref{UErrorCode}(0)
    p = ccall(@libucsdet(getLanguage), Ptr{UInt8}, (Ptr{Cvoid},Ptr{UErrorCode}), csmatch.p, err)
    SUCCESS(err[]) || error("ICU: $(err[]), could not get language")
    unsafe_string(p)
end

"""
   Get the entire input text as a UChar string, placing it into a caller-supplied buffer.  A terminating
   NUL character will be appended to the buffer if space is available.

   The number of UChars in the output string, not including the terminating NUL, is returned.

   If the supplied buffer is smaller than required to hold the output, the contents of the buffer are undefined.
   The full output string length (in UChars) is returned as always, and can be used to allocate a buffer of the
   correct size.

   Arguments:
   ucsm     The charset match object.
   buf      A UChar buffer to be filled with the converted text data.
   cap      The capacity of the buffer in UChars.
   status   Any error conditions are reported back in this variable.

   Returns: The number of UChars in the output string.
"""
function get_uchars(csmatch::UCharsetMatch)
    csmatch.p != C_NULL || throw(UndefRefError())
    err = Ref{UErrorCode}(0)
    len = _get_uchars(csmatch, C_NULL, 0, err)
    dest = _allocate(UInt16, len+1)
    len = _get_uchars(csmatch, dest, len+1, err)
    SUCCESS(err[]) || error("ICU: $(err[]), could not get string from UCharsetMatch object")
    Str(UTF16CSE, dest[1:len])
end

_get_uchars(p::Ptr{Cvoid}, buf, siz, err) =
    ccall(@libucsdet(getUChars), Int32,
          (Ptr{Cvoid},Ptr{UInt8},Int32,Ptr{UErrorCode}), p, buf, siz, err)

"""
   Get an iterator over the set of all detectable charsets -
   over the charsets that are known to the charset detection service.

   The returned UEnumeration provides access to the names of the charsets.

   The state of the Charset detector that is passed in does not affect the result of this function,
   but requiring a valid, open charset detector as a parameter insures that the charset detection
   service has been safely initialized and that the required detection data is available.

   <b>Note:</b> Multiple different charset encodings in a same family may use a single shared name
   in this implementation. For example, this method returns an array including "ISO-8859-1" (ISO Latin 1),
   but not including "windows-1252" (Windows Latin 1). However, actual detection result could be "windows-1252"
   when the input data matches Latin 1 code points with any points only available in "windows-1252".

   Arguments:
   ucsd      Charset detector.

   Returns:  iterator providing access to the detectable charset names.
"""
function get_all_detectable_charsets(csd::UCharsetDetector)
    csd.p != C_NULL || throw(UndefRefError())
    err = Ref{UErrorCode}(0)
    p = ccall(@libucsdet(getAllDetectableCharsets), Ptr{Cvoid},
              (Ptr{Cvoid}, Ptr{UErrorCode}), csd.p, err)
    SUCCESS(err[]) || error("ICU: $(err[]), could not get all detected charsets")
    p
end

"""
    Test whether input filtering is enabled for this charset detector.

    Input filtering removes text that appears to be HTML or xml markup from the input
    before applying the code page detection heuristics.

    Arguments:
    ucsd   The charset detector to check.

    Returns: TRUE if filtering is enabled.
"""
input_filter_enabled(csd::UCharsetDetector) =
    ccall(@libucsdet(isInputFilterEnabled), UBool, (Ptr{Cvoid},), csd.p)

"""
   Enable filtering of input text. If filtering is enabled, text within angle brackets ("<" and ">") will be removed
   before detection, which will remove most HTML or xml markup.

   Arguments:
   ucsd    the charset detector to be modified.
   filter  <code>true</code> to enable input text filtering.

   Returns: The previous setting.
"""
enable_input_filter(csd::UCharsetDetector, filter::Bool=true) =
    ccall(@libucsdet(enableInputFilter), UBool, (Ptr{Cvoid},Bool), csd.p, filter)
