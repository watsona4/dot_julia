# This file includes code originally part of Julia
# Licensed under MIT License, see LICENSE.md

# The plan is to rewrite all of the functionality to not use the utf8proc library,
# and to use tables loaded up on initialization, as with StringLiterals.jl

# Currently, for characters outside the Latin1 subset, this depends on the following C calls:

# utf8proc_errmsg
# utf8proc_charwidth
# utf8proc_category
# utf8proc_category_string
# utf8proc_tolower
# utf8proc_toupper
# utf8proc_totitle

# For grapheme segmentation, this currently depends on the following 2 C calls:

# utf8proc_grapheme_break
# utf8proc_grapheme_break_stateful

############################################################################

utf8proc_error(result) =
    error(unsafe_string(ccall(:utf8proc_errmsg, Cstring, (Cssize_t,), result)))

utf8proc_charwidth(ch) = Int(ccall(:utf8proc_charwidth, Cint, (UInt32,), ch))

@inline utf8proc_cat(ch) = ccall(:utf8proc_category, Cint, (UInt32,), ch)
@inline utf8proc_cat_abbr(ch) =
    unsafe_string(ccall(:utf8proc_category_string, Cstring, (UInt32,), ch))

#@inline _lowercase_u(ch) = ccall(:utf8proc_tolower, UInt32, (UInt32,), ch)
#@inline _uppercase_u(ch) = ccall(:utf8proc_toupper, UInt32, (UInt32,), ch)
#@inline _titlecase_u(ch) = ccall(:utf8proc_totitle, UInt32, (UInt32,), ch)

############################################################################

# iterators for grapheme segmentation

is_grapheme_break(c1::CodeUnitTypes, c2::CodeUnitTypes) =
    !(c1 <= 0x10ffff && c2 <= 0x10ffff) ||
    ccall(:utf8proc_grapheme_break, Bool, (UInt32, UInt32), c1, c2)

# Stateful grapheme break required by Unicode-9 rules: the string
# must be processed in sequence, with state initialized to Ref{Int32}(0).
# Requires utf8proc v2.0 or later.
is_grapheme_break!(state::Ref{Int32}, c1::CodeUnitTypes, c2::CodeUnitTypes) =
    ((c1 <= 0x10ffff && c2 <= 0x10ffff)
     ? ccall(:utf8proc_grapheme_break_stateful, Bool, (UInt32, UInt32, Ref{Int32}), c1, c2, state)
     : (state[] = 0; true))

is_grapheme_break(c1::Chr, c2::Chr) = is_grapheme_break(codepoint(c1), codepoint(c2))
is_grapheme_break(state::Ref{UInt32}, c1::Chr, c2::Chr) =
    is_grapheme_break(state, codepoint(c1), codepoint(c2))
