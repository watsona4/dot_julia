struct ZeroTo{T<:Signed} <: AbstractUnitRange{T}
    stop::T
    function ZeroTo{T}(stop) where T
        Base.depwarn("ZeroTo is deprecated, use ZeroRange instead", :ZeroTo)
        new{T}(max(T(-1), stop))
    end
end
ZeroTo(stop::T) where {T<:Signed} = ZeroTo{T}(stop)

Base.length(r::ZeroTo) = r.stop+1

Base.length(r::ZeroTo{T}) where {T<:Union{Int,Int64}} = T(r.stop+1)

let smallint = (Int === Int64 ?
                Union{Int8,UInt8,Int16,UInt16,Int32,UInt32} :
                Union{Int8,UInt8,Int16,UInt16})
    Base.length(r::ZeroTo{T}) where {T <: smallint} = Int(r.stop)+1
end

Base.first(r::ZeroTo{T}) where {T} = zero(T)

function Base.iterate(r::ZeroTo{T}) where {T}
    x = zero(T)
    return (r.stop <= x ? nothing : (x,x))
end
function Base.iterate(r::ZeroTo{T}, i) where T
    x = i + one(T)
    return (x > oftype(x, r.stop) ? nothing : (x,x))
end

@inline function Base.getindex(v::ZeroTo{T}, i::Integer) where T
    @boundscheck ((i > 0) & (i <= length(v))) || Base.throw_boundserror(v, i)
    convert(T, i-1)
end

@inline function Base.getindex(r::ZeroTo{T}, s::ZeroTo) where T
    @boundscheck checkbounds(r, s)
    ZeroTo(T(s.stop))
end

@inline function Base.getindex(r::ZeroTo{T}, s::AbstractUnitRange) where T
    @boundscheck checkbounds(r, s)
    T(first(s)-1):T(last(s)-1)
end

Base.intersect(r::ZeroTo, s::ZeroTo) = ZeroTo(min(r.stop,s.stop))

Base.promote_rule(::Type{ZeroTo{T1}},::Type{ZeroTo{T2}}) where {T1,T2} =
    ZeroTo{promote_type(T1,T2)}
Base.convert(::Type{ZeroTo{T}}, r::ZeroTo{T}) where {T<:Real} = r
Base.convert(::Type{ZeroTo{T}}, r::ZeroTo) where {T<:Real} = ZeroTo{T}(r.stop)
ZeroTo{T}(r::ZeroTo) where {T} = convert(Type{ZeroTo{T}}, r)

Base.show(io::IO, r::ZeroTo) = print(io, typeof(r).name, "(", r.stop, ")")
