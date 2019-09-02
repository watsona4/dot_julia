"""
```
    AlphaNumeral
```
Numbers represented as alphabets. ex. A, B, C,... from 27 onwards AA, BB, CC etc.
"""
struct AlphaNumeral <: Integer
    val::Int
    str::String
end

"""
```
    AlphaNumeral(str::String)
    AlphaNumeral(n::Int)
```
Constructors for `AlphaNumeral`.
"""
AlphaNumeral(str::String) = parse(AlphaNumeral, str)
AlphaNumeral(n::T) where T <: Integer = convert(AlphaNumeral, n)

Base.hash(num::AlphaNumeral) = xor(hash(num.str), hash(num.val))

Base.typemax(::Type{AlphaNumeral}) = 156 # ZZZZZZ
Base.typemin(::Type{AlphaNumeral}) = 1

"""
```
    @an_str(str)
```
String decorator for `AlphaNumeral` definitions.

#Example
```
julia> an"AA"
LabelNumerals.AlphaNumeral(27, "AA")
```
"""
macro an_str(str)
    AlphaNumeral(str)
end

Base.convert(::Type{T}, num::AlphaNumeral) where T <: Integer =
    convert(T, num.val)

function Base.parse(::Type{AlphaNumeral}, str::String)
    s = uppercase(str)
    c = s[1]
    cnt = 0
    for a in s
        a != c && throw(DomainError(-2, "Characters must be repeated"))
        cnt += 1
    end
    val = 26*(cnt - 1) + (c - 'A') + 1
    typemin(AlphaNumeral) <= val <= typemax(AlphaNumeral) &&
        return AlphaNumeral(val, str)
    throw(DomainError(-1, "Value out of range"))
end

function Base.convert(::Type{AlphaNumeral}, val::Int)
    if typemin(AlphaNumeral) <= val <= typemax(AlphaNumeral)
        n = div(val, 26)
        r = rem(val, 26)
        if r == 0
            r = 26
            n -= 1
        end
        str = string(fill(Char('A' + r -1),(n+1))...)
        return AlphaNumeral(val, str)
    end
    throw(DomainError(-1, "Value out of range"))
end
