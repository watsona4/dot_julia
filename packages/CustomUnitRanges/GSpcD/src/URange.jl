struct URange{T<:Real} <: AbstractUnitRange{T}
    start::T
    stop::T
    URange{T}(start, stop) where {T} = new{T}(start, urange_last(start,stop))
end
URange(start::T, stop::T) where {T<:Real} = URange{T}(start, stop)

urange_last(::Bool, stop::Bool) = stop
urange_last(start::T, stop::T) where {T<:Integer} =
    ifelse(stop >= start, stop, convert(T,start-one(stop-start)))
urange_last(start::T, stop::T) where {T} =
    ifelse(stop >= start, convert(T,start+floor(stop-start)),
                          convert(T,start-one(stop-start)))

function Base.iterate(r::URange{T}) where {T}
    r.start > r.stop && return nothing
    x = oftype(r.start + one(T), r.start)
    return (x,x)
end
function Base.iterate(r::URange{T}, i) where T
    x = i + one(T)
    return (x > oftype(x, r.stop) ? nothing : (x,x))
end

Base.intersect(r::URange{T1}, s::URange{T2}) where {T1<:Integer,T2<:Integer} = URange(max(first(r),first(s)), min(last(r),last(s)))

@inline function Base.getindex(r::URange{R}, s::AbstractUnitRange{S}) where {R,S<:Integer}
    @boundscheck checkbounds(r, s)
    f = first(r)
    strt = f + first(s) - 1
    URange{R}(strt, strt+length(s)-1)
end

Base.promote_rule(::Type{URange{T1}},::Type{URange{T2}}) where {T1,T2} =
    URange{promote_type(T1,T2)}
Base.convert(::Type{URange{T}}, r::URange{T}) where {T<:Real} = r
Base.convert(::Type{URange{T}}, r::URange) where {T<:Real} = URange{T}(r.start, r.stop)

Base.promote_rule(::Type{URange{T1}}, ::Type{UR}) where {T1,UR<:AbstractUnitRange} =
    URange{promote_type(T1,eltype(UR))}
Base.promote_rule(::Type{UnitRange{T2}}, ::Type{URange{T1}}) where {T1,T2} =
    URange{promote_type(T1,T2)}
Base.convert(::Type{URange{T}}, r::AbstractUnitRange) where {T<:Real} = URange{T}(first(r), last(r))
URange{T}(r::AbstractUnitRange) where {T} = convert(Type{URange{T}}, r)

Base.show(io::IO, r::URange) = print(io, typeof(r).name, '(', repr(first(r)), ',', repr(last(r)), ')')
