
# parse readable numeric strings

parse_readable(::Type{T}, s::String, ch::Char) where {T <: Union{Integer, AbstractFloat}} =
    Base.parse(T, join(split(s,ch),""))

parse_readable(::Type{T}, s::String, ch1::Char, ch2::Char) where {T <: AbstractFloat} =
    Base.parse(T, join(split(s,(ch1,ch2)),""))

"""
how many times does char c occur in string s
"""
function count_char(s::String, c::Char)
    r = (c=='.') ? Regex("\\.") : Regex(string(c))
    return length( matchall(r,s) )
end
