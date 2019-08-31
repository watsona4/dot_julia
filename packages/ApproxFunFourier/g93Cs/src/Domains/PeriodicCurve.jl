export PeriodicCurve

struct PeriodicCurve{S<:Space,T,VT} <: PeriodicDomain{T}
    curve::Fun{S,T,VT}
end



==(a::PeriodicCurve, b::PeriodicCurve) = a.curve == b.curve
isempty(::PeriodicCurve) = false

points(c::PeriodicCurve, n::Integer) = c.curve.(points(domain(c.curve),n))


checkpoints(d::PeriodicCurve) = fromcanonical.(Ref(d),checkpoints(domain(d.curve)))

for op in (:(leftendpoint),:(rightendpoint),:(rand))
    @eval $op(c::PeriodicCurve) = c.curve($op(domain(c.curve)))
end


canonicaldomain(c::PeriodicCurve) = domain(c.curve)

fromcanonical(c::PeriodicCurve{S,T},x) where {S<:Space,T<:Number} = c.curve(x)
function tocanonical(c::PeriodicCurve,x)
    rts=roots(c.curve-x)
    @assert length(rts)==1
    first(rts)
end


fromcanonicalD(c::PeriodicCurve,x)=differentiate(c.curve)(x)

function indomain(x,c::PeriodicCurve)
    rts=roots(c.curve-x)
    if length(rts) ≠ 1
        false
    else
        in(first(rts),canonicaldomain(c))
    end
end


reverseorientation(d::PeriodicCurve) = PeriodicCurve(reverseorientation(d.curve))

isambiguous(d::PeriodicCurve) = ncoefficients(d.curve)==0 && isambiguous(domain(d.curve))

convert(::Type{PeriodicCurve{S,T}},::AnyDomain) where {S,T}=Fun(S(AnyDomain()),[NaN])


arclength(d::PeriodicCurve) = linesum(ones(d))
