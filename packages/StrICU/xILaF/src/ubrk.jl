# ubrk.jl - Wrapper for ICU (International Components for Unicode) library

# Some content of the documentation strings was derived from the ICU header files ubrk.h
# (Those portions copyright (C) 1996-2015, International Business Machines Corporation and others)

"""
UBRK defines constants for ICU break iterator API:
CHARACTER, TITLE, COUNT, DONE,
WORD, WORD_TAG, WORD_NONE, WORD_NONE_LIMIT, WORD_NUMBER, WORD_NUMBER_LIMIT,
WORD_LETTER, WORD_LETTER_LIMIT, WORD_KANA, WORD_KANA_LIMIT, WORD_IDEO, WORD_IDEO_LIMIT,
LINE, LINE_TAG, LINE_SOFT, LINE_SOFT_LIMIT, LINE_HARD, LINE_HARD_LIMIT,
SENTENCE, SENTENCE_TAG, SENTENCE_TERM, SENTENCE_TERM_LIMIT, SENTENCE_SEP, SENTENCE_SEP_LIMIT
"""
module UBRK

const CHARACTER = Int32(0)
const WORD      = Int32(1)
const LINE      = Int32(2)
const SENTENCE  = Int32(3)
const TITLE     = Int32(4) # Deprecated API (use word break iterator)
const COUNT     = Int32(5)

"""Value indicating all text boundaries have been returned."""
const DONE      = Int32(-1)

"""
    Constants for the word break tags returned by ICU.get_rule_status().
    A range of values is defined for each category of word, to allow for
    further subdivisions of a category in future releases.
    Applications should check for tag values falling within the range,
    rather than for single individual values.
"""
const WORD_TAG = 0

"""
    Tag value for "words" that do not fit into any of other categories.
    Includes spaces and most punctuation.
"""
const WORD_NONE  = Int32(0)
"""
    Upper bound for tags for uncategorized words.
"""
const WORD_NONE_LIMIT = Int32(100)
"""
    Tag value for words that appear to be numbers, lower limit.
"""
const WORD_NUMBER     = Int32(100)
"""
    Tag value for words that appear to be numbers, upper limit.
"""
const WORD_NUMBER_LIMIT   = Int32(200)
"""
    Tag value for words that contain letters, excluding hiragana, katakana or
    ideographic characters, lower limit.
"""
const WORD_LETTER         = Int32(200)
"""
    Tag value for words containing letters, upper limit
"""
const WORD_LETTER_LIMIT   = Int32(300)
"""
    Tag value for words containing kana characters, lower limit
"""
const WORD_KANA           = Int32(300)
"""
    Tag value for words containing kana characters, upper limit
"""
const WORD_KANA_LIMIT     = Int32(400)
"""
    Tag value for words containing ideographic characters, lower limit
"""
const WORD_IDEO           = Int32(400)
"""
    Tag value for words containing ideographic characters, upper limit
"""
const WORD_IDEO_LIMIT     = Int32(500)

"""
    Constants for the line break tags returned by ICU.get_rule_status().
    A range of values is defined for each category of word, to allow for
    further subdivisions of a category in future releases.
    Applications should check for tag values falling within the range,
    rather than for single individual values.
"""
const LINE_TAG = 0

"""
    Tag value for soft line breaks, positions at which a line break
    is acceptable but not required
"""
const LINE_SOFT            = Int32(0)
"""
    Upper bound for soft line breaks.
"""
const LINE_SOFT_LIMIT      = Int32(100)
"""
    Tag value for a hard, or mandatory line break
"""
const LINE_HARD            = Int32(100)
"""
    Upper bound for hard line breaks.
"""
const LINE_HARD_LIMIT      = Int32(200)

"""
    Constants for the sentence break tags returned by ICU.get_rule_status().
    A range of values is defined for each category of sentence, to allow for
    further subdivisions of a category in future releases.
    Applications should check for tag values falling within the range,
    rather than for single individual values.
"""
const SENTENCE_TAG = 0

"""
    Tag value for for sentences  ending with a sentence terminator
    ('.', '?', '!', etc.) character, possibly followed by a
    hard separator (CR, LF, PS, etc.)
"""
const SENTENCE_TERM       = Int32(0)
"""
    Upper bound for tags for sentences ended by sentence terminators.
"""
const SENTENCE_TERM_LIMIT = Int32(100)
"""
    Tag value for for sentences that do not contain an ending
    sentence terminator ('.', '?', '!', etc.) character, but
    are ended only by a hard separator (CR, LF, PS, etc.) or end of input.
"""
const SENTENCE_SEP        = Int32(100)
"""
    Upper bound for tags for sentences ended by a separator.
"""
const SENTENCE_SEP_LIMIT  = Int32(200)
end # module UBRK

export UBRK, UBrk

macro libbrk(s)     ; _libicu(s, iculib,     "ubrk_")     ; end

const UBrkType = Int32

const UBrkStrTypes = Union{Vector{UInt16}, UTF16Str}

"""
    UBrk is a type along with methods for finding the location of boundaries in text.
    A UBrk maintains a current position and scan over text returning the index of characters
    where boundaries occur.

    Line boundary analysis determines where a text string can be broken when line-wrapping.
    The mechanism correctly handles punctuation and hyphenated words.

    Note: The locale keyword "lb" can be used to modify line break behavior according to
    the CSS level 3 line-break options, see <http://dev.w3.org/csswg/css-text/#line-breaking>.
    For example: "ja@lb=strict", "zh@lb=loose".

    Sentence boundary analysis allows selection with correct interpretation of periods within
    numbers and abbreviations, and trailing punctuation marks such as quotation marks and
    parentheses.

    Note: The locale keyword "ss" can be used to enable use of segmentation suppression data
    (preventing breaks in English after abbreviations such as "Mr." or "Est.", for example),
    as follows: "en@ss=standard".

    Word boundary analysis is used by search and replace functions, as well as within text
    editing applications that allow the user to select words with a double click.
    Word selection provides correct interpretation of punctuation marks within and following
    words. Characters that are not part of a word, such as symbols or punctuation marks,
    have word-breaks on both sides.

    Character boundary analysis identifies the boundaries of "Extended Grapheme Clusters",
    which are groupings of codepoints that should be treated as character-like units for
    many text operations.

    Please see Unicode Standard Annex #29, Unicode Text Segmentation,
    http://www.unicode.org/reports/tr29/ for additional information
    on grapheme clusters and guidelines on their use.

    Title boundary analysis locates all positions, typically starts of words, that should
    be set to Title Case when title casing the text.

    The text boundary positions are found according to the rules described in
    Unicode Standard Annex #29, Text Boundaries, and Unicode Standard Annex #14,
    Line Breaking Properties.  These are available at http://www.unicode.org/reports/tr14/
    and http://www.unicode.org/reports/tr29/.
"""
mutable struct UBrk
    p::Ptr{Cvoid}
    s
    r

    function UBrk(kind::Integer, str::UBrkStrTypes, loc::ASCIIStr)
        err = Ref{UErrorCode}(0)
        p = ccall(@libbrk(open), Ptr{Cvoid},
                  (UBrkType, Cstring, Ptr{UChar}, Int32, Ptr{UErrorCode}),
                  kind, loc, str, length(str), err)
        @assert SUCCESS(err[])
        # Retain pointer to input vector, otherwise it might be GCed
        self = new(p, str, Cvoid())
        finalizer(self, close)
        self
    end
    function UBrk(kind::Integer, str::UBrkStrTypes)
        err = Ref{UErrorCode}(0)
        p = ccall(@libbrk(open), Ptr{Cvoid},
                  (UBrkType, Ptr{UInt8}, Ptr{UChar}, Int32, Ptr{UErrorCode}),
                  kind, C_NULL, str, length(str), err)
        @assert SUCCESS(err[])
        # Retain pointer to input vector, otherwise it might be GCed
        self = new(p, str, Cvoid())
        finalizer(self, close)
        self
    end
    function UBrk(rules::UBrkStrTypes, str::UBrkStrTypes)
        err = Ref{UErrorCode}(0)
        # Temporary disable UParseError and pass C_NULL
        #p_err = Ref(UParseError())
        p = ccall(@libbrk(openRules), Ptr{Cvoid},
                  (Ptr{UChar}, Int32, Ptr{UChar}, Int32, Ptr{UParseError}, Ptr{UErrorCode}),
                  rules, length(rules), str, length(str), C_NULL, err)
        @assert SUCCESS(err[])
        # Retain pointer to input vector, otherwise it might be GCed
        self = new(p, str, rules)
        finalizer(self, close)
        self
    end
end

UBrk(kind::Integer, str::UBrkStrTypes, loc::AbstractString) = UBrk(kind, str, cvt_ascii(loc))

"""
    Close the Break Iterator and return any resource, if not already closed
"""
function close(bi::UBrk)
    bi.p == C_NULL && return
    ccall(@libbrk(close), Cvoid, (Ptr{Cvoid},), bi.p)
    bi.p = C_NULL
    bi.s = Cvoid()
    bi.r = Cvoid()
    nothing
end

"""
    Determine the most recently-returned text boundary.

    Arguments:
    bi - The break iterator to use.
    Returns the character index most recently returned by next, previous, first, or last.
"""
current(bi::UBrk) = ccall(@libbrk(current), Int32, (Ptr{Cvoid},), bi.p)

"""
    Advance the iterator to the boundary following the current boundary.
    Returns the character index of the next text boundary, or UBRK.DONE
    if all text boundaries have been returned.
"""
next(bi::UBrk) = ccall(@libbrk(next), Int32, (Ptr{Cvoid},), bi.p)

"""
    Set the iterator position to the boundary preceding the current boundary.
    Returns the character index of the preceding text boundary, or UBRK.DONE
    if all text boundaries have been returned.
"""
previous(bi::UBrk) = ccall(@libbrk(previous), Int32, (Ptr{Cvoid},), bi.p)

"""
    Set the iterator position to zero, the start of the text being scanned.
    Returns the new iterator position (zero).
"""
first(bi::UBrk) = ccall(@libbrk(first), Int32, (Ptr{Cvoid},), bi.p)

"""
    Set the iterator position to the index immediately <EM>beyond</EM> the last character in
    the text being scanned.
    This is not the same as the last character.
    Returns the character offset immediately <EM>beyond</EM> the last character in the
    text being scanned.
"""
last(bi::UBrk) = ccall(@libbrk(last), Int32, (Ptr{Cvoid},), bi.p)

"""
    Set the iterator position to the first boundary preceding the specified offset.
    The new position is always smaller than offset, or UBRK.DONE

    Arguments:
    bi - The break iterator to use
    offset - The offset to begin scanning.
    Returns the text boundary preceding offset, or UBRK.DONE
"""
preceding(bi::UBrk, off) = ccall(@libbrk(preceding), Int32, (Ptr{Cvoid}, Int32), bi.p, off)

"""
    Advance the iterator to the first boundary following the specified offset.
    The value returned is always greater than offset, or UBRK.DONE

    Arguments:
    - bi - The break iterator to use.
    - offset - The offset to begin scanning.
    Returns the text boundary following offset, or UBRK.DONE
"""
following(bi::UBrk, off) = ccall(@libbrk(following), Int32, (Ptr{Cvoid}, Int32), bi.p, off)

"""
    Get a locale for which text breaking information is available.
    A UBrk in a locale returned by this function will perform the correct
    text breaking for the locale.

    Arguments:
    index - The index of the desired locale.

    Returns: A locale for which number text breaking information is available, or 0 if none.
"""
function get_available(index)
    loc = ccall(@libbrk(getAvailable), Ptr{UInt8}, (Int32, ), index)
    ASCIIStr(loc == C_NULL ? "" : loc)
end

"""
    Determine how many locales have text breaking information available.
    This function is most useful as determining the loop ending condition for
    calls to get_available.

    Returns: the number of locales for which text breaking information is available.
"""
count_available() = ccall(@libbrk(countAvailable), Int32, ())

"""
    Returns true if the specfied position is a boundary position.  As a side
    effect, leaves the iterator pointing to the first boundary position at
    or after "offset".

    Arguments:
    - bi - The break iterator to use.
    - offset - The offset to check.

    Returns true if "offset" is a boundary position.
"""
isboundary(bi::UBrk, off) = ccall(@libbrk(isBoundary), Int32, (Ptr{Cvoid}, Int32), bi.p, off) != 0

"""
    Return the status from the break rule that determined the most recently returned break
    position.  The values appear in the rule source within brackets, {123}, for example.
    For rules that do not specify a status, a default value of 0 is returned.
"""
get_rule_status(bi::UBrk) =
    ccall(@libbrk(getRuleStatus), Int32, (Ptr{Cvoid},), bi.p)

"""
    Get the statuses from the break rules that determined the most recently
    returned break position.  The values appear in the rule source within brackets,
    {123}, for example.  The default status value for rules that do not explicitly
    provide one is zero.

    For word break iterators, the possible values are defined module UBRK

    Arguments:
    bi - The break iterator to use
    fillinvec - an array to be filled in with the status values.
    capacity - the length of the supplied vector.  A length of zero causes
               the function to return the number of status values, in the
               normal way, without attemtping to store any values.
    status - receives error codes.

    Returns: The number of rule status values from rules that determined
             the most recent boundary returned by the break iterator.
"""
function get_rule_status_vec(bi::UBrk, fillinvec::Vector{Int32})
    err = Ref{UErrorCode}(0)
    cnt = ccall(@libbrk(getRuleStatusVec), Int32,
                (Ptr{Cvoid}, Ptr{Int32}, Int32,  Ptr{UErrorCode}),
                bi.p, fillinvec, length(fillinvec), err)
    @assert SUCCESS(err[])
    cnt
end

function get_rule_status_len(bi::UBrk)
    err = Ref{UErrorCode}(0)
    cnt = ccall(@libbrk(getRuleStatusVec), Int32,
                (Ptr{Cvoid}, Ptr{Int32}, Int32,  Ptr{UErrorCode}),
                bi.p, C_NULL, 0, err)
    @assert SUCCESS(err[])
    cnt
end

"""
    Return the locale of the break iterator. You can choose between
    the valid and the actual locale.

    Arguments:
    bi - break iterator
    type - locale type (valid or actual)
    status - error code

    Return: locale string
"""
function get_locale_by_type(bi::UBrk, typ, status)
    # ccall(@libbrk(getLocaleByType), Ptr{UInt8},
    #       (const UBreakIterator *bi, ULocDataLocaleType type, UErrorCode* status);
end

"""
    Sets an existing iterator to point to a new piece of text

    Arguments:
    bi - The iterator to use
    text - The text to be set

    Returns status code
"""
function set! end

function set!(bi::UBrk, v, pnt::Ptr{UInt16}, len)
    err = Ref{UErrorCode}(0)
    ccall(@libbrk(setText), Cvoid,
          (Ptr{Cvoid}, Ptr{UChar}, Int32, Ptr{UErrorCode}),
          bi.p, v, len, err)
    # Retain pointer so that it won't be GCed
    bi.s = v
    @assert SUCCESS(err[])
    err[]
end

set!(bi::UBrk, str::AbstractString) = set!(bi, cvt_utf16(str))
set!(bi::UBrk, str::WordStrings) =
    @preserve str set!(bi, str, pointer(str), ncodeunits(str))
set!(bi::UBrk, v::Vector{UInt16}) =
    @preserve v set!(bi, v, pointer(v), length(v))

"""
    Sets an existing iterator to point to a new piece of text.

    All index positions returned by break iterator functions are
    native indices from the UText. For example, when breaking UTF-8
    encoded text, the break positions returned by next, previous, etc.
    will be UTF-8 string indices, not UTF-16 positions.

    Arguments:
    bi - The iterator to use
    text - The text to be set.
           This function makes a shallow clone of the supplied UText.  This means
           that the caller is free to immediately close or otherwise reuse the
           UText that was passed as a parameter, but that the underlying text itself
           must not be altered while being referenced by the break iterator.

    Returns status code
"""
function set!(bi::UBrk, t::UText)
    err = Ref{UErrorCode}(0)
    ccall(@libbrk(setUText), Cvoid,
          (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{UErrorCode}),
          bi.p, t.p, err)
    @assert SUCCESS(err[])
    err[]
end
