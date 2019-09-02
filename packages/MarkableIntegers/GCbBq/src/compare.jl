for OP in (:(==), :(!=), :(<=), :(>=), :(<), :(>))
    @eval begin
        function $OP(a::T, b::T) where {T<:MarkableInteger}
            ia = ityped(a) >> 1
            ib = ityped(b) >> 1
            return $OP(ia, ib)
        end
        function $OP(a::T1, b::T2) where {T1<:MarkableInteger, T2<:MarkableInteger}
            ia = ityped(a) >> 1
            ib = ityped(b) >> 1
            return $OP(ia, ib)
        end
        function $OP(a::T1, b::T2) where {T1<:MarkableInteger, T2<:Union{Signed,Unsigned}}
            ia = ityped(a) >> 1
            return $OP(ia, b)
        end
        function $OP(a::T1, b::T2) where {T2<:MarkableInteger, T1<:Union{Signed,Unsigned}}
            ib = ityped(b) >> 1
            return $OP(a, ib)
        end
    end
end

function isless(a::T, b::T)  where{T<:MarkableInteger}
    itype(a) === itype(b) && return false
    a_nomark = unmark(a)
    b_nomark = unmark(b)
    a_nomark === b_nomark && return ismarked(a)
    a_nomark < b_nomark
end

@inline function isequal(a::T, b::T)  where{T<:MarkableInteger}
    itype(a) === itype(b)
end
