"""
```
    LookupNumeral
```
Numbers represented as from a lookup table. No digits or additional system of extension
possible. Only numbers available in the lookup table are valid.
"""
struct LookupNumeral <: Integer
    val::Int
    str::String
end

"""
```
    LookupNumeral(str::String)
    LookupNumeral(n::Int)
```
Constructors for `LookupNumeral`.
"""
LookupNumeral(str::String) = parse(LookupNumeral, str)
LookupNumeral(n::Int) = convert(LookupNumeral, n)

Base.hash(num::LookupNumeral) = xor(hash(num.str), hash(num.val))

LOOKUP_A2N = Dict(
    "One" => 1,
    "Two" => 2,
    "Three" => 3,
    "Four" => 4,
    "Five" => 5,
    "Six" => 6,
    "Seven" => 7,
    "Eight" => 8,
    "Nine" => 9,
    "Ten" => 10,
    "Eleven"=> 11,
    "Twelve" => 12,
    "Thirteen" => 13,
    "Fourteen" => 14,
    "Fifteen" => 15,
    "Sixteen" => 16,
    "Seventeen" => 17,
    "Eighteen" => 18,
    "Nineteen" => 19,
    "Twenty" => 20
)

function reverse_lookup(din::Dict{String,Int})
    dout = Dict{Int, String}()
    for (key, value) in din
        dout[value] = key
    end
    return dout
end


LOOKUP_N2A = reverse_lookup(LOOKUP_A2N)

LOOKUP_TYPEMAX = 20
LOOKUP_TYPEMIN = 1

"""
```
    registerLookupNumerals(str)
```
`LookupNumeral` can be set up by providing a mapping as a `Dict{String, Int}`.
The `minval` and `maxval` provide the limits of the domains in this number system.
"""
function registerLookupNumerals(d::Dict{String,Int}, minval, maxval)
    global LOOKUP_A2N, LOOKUP_N2A, LOOKUP_TYPEMAX, LOOKUP_TYPEMIN
    LOOKUP_A2N = d
    LOOKUP_N2A = reverse_lookup(LOOKUP_A2N)
    LOOKUP_TYPEMIN = minval
    LOOKUP_TYPEMAX = maxval
end

Base.typemax(::Type{LookupNumeral}) = LOOKUP_TYPEMAX
Base.typemin(::Type{LookupNumeral}) = LOOKUP_TYPEMIN

"""
```
    @ln_str(str)
```
String decorator for `LookupNumeral` definitions.

#Example

```
julia> ln"Three"
LabelNumerals.LookupNumeral(3, "Three")
```
"""
macro ln_str(str)
    LookupNumeral(str)
end

Base.convert(::Type{T}, num::LookupNumeral) where T <: Integer =
    convert(T, num.val)

function Base.parse(::Type{LookupNumeral}, str::String)
    haskey(LOOKUP_A2N, str) && return LookupNumeral(LOOKUP_A2N[str], str)
    throw(DomainError(-1, "Value out of range"))
end

function Base.convert(::Type{LookupNumeral}, val::Int)
    haskey(LOOKUP_N2A, val) && return LookupNumeral(val, LOOKUP_N2A[val])
    throw(DomainError(-1, "Value out of range"))
end
