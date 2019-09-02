# Base 26 number where alphabets are numbers.

"""
```
    AlphaNumNumeral
```
Numbers represented as alphabets as a base26 number where A, B, C represent
digits.
A = 0, B = 1, ..., Z = 25 etc.
"""
struct AlphaNumNumeral <: Integer
    val::Int
    str::String
end

"""
```
    AlphaNumNumeral(str::String)
    AlphaNumNumeral(n::Int)
```
Constructors for `AlphaNumNumeral`.
"""
AlphaNumNumeral(str::String) = parse(AlphaNumNumeral, str)
AlphaNumNumeral(n::Int) = convert(AlphaNumNumeral, n)

Base.hash(num::AlphaNumNumeral) = xor(hash(num.str), hash(num.val))

"""
```
    @ann_str(str)
```
String decorator for `AlphaNumNumeral` definitions.

#Example

```
julia> ann"BB"
LabelNumerals.AlphaNumNumeral(27, "BB")
```
"""
macro ann_str(str)
    AlphaNumNumeral(str)
end

Base.convert(::Type{T}, num::AlphaNumNumeral) where T <: Integer =
    convert(T, num.val)

function Base.parse(::Type{AlphaNumNumeral}, str::String)
    s = uppercase(str)
    val = 0
    for a in s
        val *= 26
        val += 'A' <= a <= 'Z' ? (a - 'A') :
            throw(DomainError(-3, "Invalid characters"))
    end
    return AlphaNumNumeral(val, str)
end

function Base.convert(::Type{AlphaNumNumeral}, val::Int)
    carr = Vector{Char}()
    tval = val
    while (tval > 0)
        r = rem(tval, 26)
        c = Char('A' + r)
        pushfirst!(carr, c)
        tval = div(tval, 26)
    end
    str = String(carr)
    return AlphaNumNumeral(val, str)
end
