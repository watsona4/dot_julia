__precompile__()

module MarkableIntegers

export Marked, Unmarked,
       @mark!, @unmark!,
       ismarked, isunmarked,
       find_marked, find_unmarked, all_marked, all_unmarked,
       MarkInt128, MarkInt64, MarkInt32, MarkInt16, MarkInt8, MarkInt,
       MarkUInt128, MarkUInt64, MarkUInt32, MarkUInt16, MarkUInt8, MarkUInt,
       MarkableSigned, MarkableUnsigned, MarkableInteger

import Base: @pure, promote_type, promote_rule, convert, mark, unmark, ismarked,
    Integer, Signed, Unsigned, signed, unsigned,
    leading_zeros, trailing_zeros, leading_ones, trailing_ones,
    convert, promote_rule, string, show,
    (<=), (<), (==), (!=), (>=), (>), isless, isequal,
    (~), (&), (|), (⊻),
    findall

import Base.Math: zero, one, iszero, isone, isinteger, typemax, typemin,
    isodd, iseven, sign, signbit, abs, copysign, flipsign,
    (+), (-), (*), (/), (\), (^), div, fld, cld, mod, rem,
    sqrt, cbrt

import Base.Checked:  add_with_overflow, sub_with_overflow, mul_with_overflow,
    checked_neg, checked_abs, checked_add, checked_sub, checked_mul,
    checked_div, checked_fld, checked_cld, checked_rem, checked_div


include("type.jl")
include("promote.jl")
include("notation.jl")
include("bits.jl")
include("compare.jl")
include("ops.jl")


end # module MarkableIntegers
