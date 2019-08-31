export IntervalCurve

struct IntervalCurve{S<:Space,T,VT} <: SegmentDomain{T}
    curve::Fun{S,T,VT}
end

==(a::IntervalCurve, b::IntervalCurve) = a.curve == b.curve

isempty(::IntervalCurve) = false

points(c::IntervalCurve, n::Integer) = c.curve.(points(domain(c.curve),n))

checkpoints(d::IntervalCurve) = fromcanonical.(Ref(d),checkpoints(domain(d.curve)))

for op in (:(leftendpoint),:(rightendpoint),:(rand))
    @eval $op(c::IntervalCurve) = c.curve($op(domain(c.curve)))
end



canonicaldomain(c::IntervalCurve) = domain(c.curve)

fromcanonical(c::IntervalCurve{S,T},x) where {S<:Space,T<:Number} = c.curve(x)
function tocanonical(c::IntervalCurve,x)
    rts=roots(c.curve-x)
    @assert length(rts)==1
    first(rts)
end


fromcanonicalD(c::IntervalCurve,x)=differentiate(c.curve)(x)

function indomain(x,c::IntervalCurve)
    rts=roots(c.curve-x)
    if length(rts) ≠ 1
        false
    else
        in(first(rts),canonicaldomain(c))
    end
end

isambiguous(d::IntervalCurve) = ncoefficients(d.curve)==0 && isambiguous(domain(d.curve))

reverseorientation(d::IntervalCurve) = IntervalCurve(reverseorientation(d.curve))
convert(::Type{IntervalCurve{S,T}},::AnyDomain) where {S,T}=Fun(S(AnyDomain()),[NaN])

arclength(d::IntervalCurve) = linesum(ones(d))