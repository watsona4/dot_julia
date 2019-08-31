__precompile__(true)
"""
StrAPI package

Copyright 2017-2018 Gandalf Software, Inc., Scott P. Jones
Licensed under MIT License, see LICENSE.md
"""
module StrAPI

using ModuleInterfaceTools
using ModuleInterfaceTools: m_eval, _stdout, _stderr

const NEW_ITERATE = VERSION >= v"0.7.0-DEV.5127"

const MaybeSub{T} = Union{T, SubString{T}} where {T<:AbstractString}

const CodeUnitTypes = Union{UInt8, UInt16, UInt32}

symstr(s...)   = Symbol(string(s...))
quotesym(s...) = Expr(:quote, symstr(s...))

@api public! found, find_result, basetype, charset, encoding, cse, codepoints

@api public StringError

@api develop NEW_ITERATE, CodeUnitTypes, CodePoints, MaybeSub, symstr, quotesym,
             _stdout, "@preserve"

@api base convert, getindex, length, map, collect, hash, sizeof, size, strides,
          pointer, unsafe_load, string, read, write, reverse,
          nextind, prevind, typemin, typemax, rem, size, ndims, first, last, eltype,
          isless, -, +, *, ^, cmp, promote_rule, one, repeat, filter,
          print, show, isimmutable, chop, chomp, replace, ascii, uppercase, lowercase,
          lstrip, rstrip, strip, lpad, rpad, split, rsplit, join, IOBuffer,
          containsnul, unsafe_convert, cconvert

# Conditionally import or export names that are only in v0.6 or in master
@api base! codeunit, codeunits, ncodeunits, codepoint, thisind, firstindex, lastindex

@static NEW_ITERATE ? (@api base iterate) : (@api base start, next, done)

@static if V6_COMPAT
    include("compat.jl")
else # !V6_COMPAT
    import Base.GC: @preserve

    function find end
    function ind2chr end
    function chr2ind end

    # Handle changes in array allocation
    create_vector(T, len)  = Vector{T}(undef, len)

    # Add new short name for deprecated hex function
    outhex(v, p=1) = string(v, base=16, pad=p)

    get_iobuffer(siz) = IOBuffer(sizehint=siz)

    const utf8crc         = Base._crc32c
    const is_lowercase    = islowercase
    const is_uppercase    = isuppercase
    const lowercase_first = lowercasefirst
    const uppercase_first = uppercasefirst

    using Base: unsafe_crc32c, Fix2

    # Location of some methods moved from Base.UTF8proc to Base.Unicode
    const UC = Base.Unicode
    const Unicode = UC

    import Base.CodeUnits

    @api base IteratorSize

    const is_letter = isletter

    pwc(c, io, str) = printstyled(io, str; color = c)

    const graphemes = UC.graphemes

end # !V6_COMPAT

@api base isequal, ==, in

pwc(c, l) = pwc(c, _stdout(), l)

pr_ul(l)     = pwc(:underline, l)
pr_ul(io, l) = pwc(:underline, io, l)

@api develop! pwc, pr_ul

const str_next = @static NEW_ITERATE ? iterate : next
str_done(str::AbstractString, i::Integer) = i > ncodeunits(str)

@api develop! str_next, str_done
@api develop unsafe_crc32c, Fix2, CodeUnits
@api public! is_lowercase, is_uppercase, lowercase_first, uppercase_first

function found end
function find_result end

"""Get the base type (of CodeUnitTypes) of a character or aligned/swapped type"""
function basetype end

"""Get the character set used by a string or character type"""
function charset end

"""Get the character set used by a string type"""
function encoding end

"""Get the character set / encoding used by a string type"""
function cse end

function _write end
function _print end
function _isvalid end
function _lowercase end
function _uppercase end
function _titlecase end
@api develop! _write, _print, _isvalid, _lowercase, _uppercase, _titlecase

const curmod = @static V6_COMPAT ? current_module() : @__MODULE__

include("errors.jl")
include("traits.jl")
include("codepoints.jl")
include("uni.jl")

@api modules Uni, StrErrors, Unicode

@api develop boundserr, strerror, nulerr, neginderr, codepoint_error,
             argerror, ascii_err, ncharerr, repeaterr, index_error

# Possibly import functions, give new names with underscores

# Todo: Should probably have a @api function for importing/defining renamed functions
const namlst = Symbol[]

for (pref, lst) in
    ((0,
      ((:textwidth,      :text_width),
       (:occursin,       :occurs_in),
       (:startswith,     :starts_with),
       (:endswith,       :ends_with))),

     (1,
      ((:xdigit, :hex_digit),
       (:cntrl,  :control),
       (:punct,  :punctuation),
       (:print,  :printable))),

     (2, (:ascii, :digit, :space, :numeric,
          :valid, :defined, :assigned, :empty,
          :latin, :bmp, :unicode))
     ), nam in lst

    oldname, newname =
        (pref == 0 ? nam : pref == 1
         ? (symstr("is", nam[1]), symstr("is_", nam[2]))
         : (symstr("is", nam), symstr("is_", nam)))

    m_eval(curmod,
           (isdefined(Base, oldname)
            ? Expr(:const, Expr(:(=), newname, oldname))
            : Expr(:function, newname)))

    push!(namlst, newname)
end
@eval @api public! $(namlst...)

# Handle renames where function was deprecated

# Todo: have function for defining and making public
function is_alphabetic end
function is_alphanumeric end
function is_graphic end
@api public! is_alphabetic, is_alphanumeric, is_graphic, is_letter

# import and add new names from UTF8proc/Unicode

const is_grapheme_break  = UC.isgraphemebreak
const is_grapheme_break! = UC.isgraphemebreak!
const category_code      = UC.category_code
const category_abbrev    = UC.category_abbrev
const category_string    = UC.category_string

@api public! is_grapheme_break, is_grapheme_break!, category_code, category_abbrev, category_string

const fnd = find
@api public! fnd, find

@api develop create_vector, outhex, get_iobuffer
@api develop! utf8crc, ind2chr, chr2ind

# Operations for find/search operations

abstract type FindOp end

struct First <: FindOp end
struct Last  <: FindOp end
struct Next  <: FindOp end
struct Prev  <: FindOp end
struct Each  <: FindOp end
struct All   <: FindOp end

abstract type Direction <: FindOp end

struct Fwd   <: Direction end
struct Rev   <: Direction end

@api public FindOp, Direction, Fwd, Rev, First, Last, Next, Prev, Each, All

@api freeze

end # module StrAPI
