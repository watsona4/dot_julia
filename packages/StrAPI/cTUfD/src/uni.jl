"""
Unicode Normalization, Category constants and documentation

Copyright 2017-2018 Gandalf Software, Inc. Scott P. Jones,
and other contributors to the UTF8proc library (for the documentation of the API)

Licensed under MIT License, see LICENSE.md
"""
module Uni

using ModuleInterfaceTools: m_eval

@enum(Category::Int8,Cn,Lu,Ll,Lt,Lm,Lo,Mn,Mc,Me,Nd,Nl,No,Pc,Pd,Ps,Pe,Pi,Pf,Po,Sm,Sc,Sk,So,
                     Zs,Zl,Zp,Cc,Cf,Cs,Co,Ci,Cm)

# strings corresponding to the category constants
const category_strings = [
    "Other, not assigned",
    "Letter, uppercase",
    "Letter, lowercase",
    "Letter, titlecase",
    "Letter, modifier",
    "Letter, other",
    "Mark, nonspacing",
    "Mark, spacing combining",
    "Mark, enclosing",
    "Number, decimal digit",
    "Number, letter",
    "Number, other",
    "Punctuation, connector",
    "Punctuation, dash",
    "Punctuation, open",
    "Punctuation, close",
    "Punctuation, initial quote",
    "Punctuation, final quote",
    "Punctuation, other",
    "Symbol, math",
    "Symbol, currency",
    "Symbol, modifier",
    "Symbol, other",
    "Separator, space",
    "Separator, line",
    "Separator, paragraph",
    "Other, control",
    "Other, format",
    "Other, surrogate",
    "Other, private use",
    "Invalid, too high",
    "Malformed, bad data",
]

Base.rem(c::Category, t::Type{T}) where {T<:Integer}  = T(Int(c))
Base.rem(c::Category, t::Type{T}) where {T<:Unsigned} = T(Int(c))
Base.:(==)(x::Category, t::Integer) = Int(x) == t
Base.:(==)(t::Integer, x::Category) = Int(x) == t
Base.:(+)(x::Category, t::Integer)  = Category(Int(x) + t)
Base.:(-)(x::Category, y::Integer)  = Category(Int(x) - y)
Base.:(-)(x::Category, y::Category) = Int(x) - Int(y)

const curmod = @static VERSION < v"0.7" ? current_module() : @__MODULE__

for i = Int(typemin(Category)):Int(typemax(Category))
    m_eval(curmod,
           Expr(:macrocall, Symbol("@doc"),
                string("Unicode Category: ", category_strings[i+1]),
                Symbol(Category(i))))
end

## Constants for calling the normalize function

"""The given UTF-8 input is NULL terminated"""
const NULLTERM  = (1<<0)

"""Unicode Versioning Stability has to be respected"""
const STABLE    = (1<<1)

"""Compatibility decomposition (i.e. formatting information is lost)"""
const COMPAT    = (1<<2)

"""Return a result with decomposed characters"""
const COMPOSE   = (1<<3)

"""Return a result with decomposed characters"""
const DECOMPOSE = (1<<4)

"""Strip "default ignorable characters" such as SOFT-HYPHEN or ZERO-WIDTH-SPACE"""
const IGNORE    = (1<<5)

"""Return an error, if the input contains unassigned codepoints"""
const REJECTNA  = (1<<6)

"""
Indicating that NLF-sequences (LF, CRLF, CR, NEL) are representing a line break,
and should be converted to the codepoint for line separation (LS)
"""
const NLF2LS    = (1<<7)

"""
Indicating that NLF-sequences are representing a paragraph break, and
should be converted to the codepoint for paragraph separation (PS)
"""
const NLF2PS    = (1<<8)

"""Indicating that the meaning of NLF-sequences is unknown"""
const NLF2LF    = (NLF2LS | NLF2PS)

"""
Strips and/or converts control characters.
NLF-sequences are transformed into space, except if one of the NLF2LS/PS/LF
options is given. HorizontalTab (HT) and FormFeed (FF) are treated as a
NLF-sequence in this case.  All other control characters are simply removed
"""
const STRIPCC   = (1<<9)

"""Performs unicode case folding, to be able to do a case-insensitive string comparison"""
const CASEFOLD  = (1<<10)

"""
Inserts 0xFF bytes at the beginning of each sequence which is representing
a single grapheme cluster (see UAX#29)
"""
const CHARBOUND = (1<<11)

"""
Lumps certain characters together.

E.g. HYPHEN U+2010 and MINUS U+2212 to ASCII "-". See lump.md for details.

If NLF2LF is set, this includes a transformation of paragraph and line separators
to ASCII line-feed (LF).
"""
const LUMP      = (1<<12)

"""
Strips all character markings.

This includes non-spacing, spacing and enclosing (i.e. accents).
@note This option works only with @ref COMPOSE or
@ref DECOMPOSE
"""
const STRIPMARK = (1<<13)

"""Strip unassigned codepoints"""
const STRIPNA    = (1<<14)

end # module Uni
