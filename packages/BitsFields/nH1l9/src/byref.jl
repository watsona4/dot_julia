struct ByRef{S,T}
   ref::Ref{T}
   
   function ByRef(::Type{S}, x::Ref{T}) where {S,T}
       return new{S,T}(x)
   end
end

@inline function ByRef(::Type{S}, ::Type{T}) where {S,T}
    return ByRef(S, Ref(zero(T)))
end

@inline function ByRef(::Type{S}, x::T) where {S,T}
    return ByRef(S, Ref(x))
end

for (S,T) in ((:Float64, :UInt64), (:Float32, :UInt32), (:Float16, :UInt16),
              (:Int64, :UInt64), (:Int32, :UInt32), (:Int16, :UInt16), (:Int8, :UInt8),
              (:UInt64, :UInt64), (:UInt32, :UInt32), (:UInt16, :UInt16), (:UInt8, :UInt8))
  @eval begin
    function ByRef(x::$S)
        u = reinterpret($T, x)
        return ByRef($S, Ref(u))
     end
  end    
end
   

@inline sourcetype(x::ByRef{S,T}) where {S,T} = S
@inline carriertype(x::ByRef{S,T}) where {S,T} = T

@inline ref(x::ByRef{S,T}) where {S,T} = x.ref
@inline val(x::ByRef{S,T}) where {S,T} = x.ref[]

@inline refvalue(x::ByRef{S,T}) where {S,T} = reinterpret(sourcetype(x), val(x))


Base.show(io::IO, x::ByRef{S,T}) where {S,T} = show(io, refvalue(x))

function set!(x::ByRef{S,T}, value::T) where {S,T} 
    x.ref[] = value
    return x
end

Base.get(x::ByRef{S,T}) where {S,T} = x.ref[]

Base.zero(::Type{ByRef{S,T}}) where {S,T} = ByRef(S,T)

Base.zero(x::ByRef{S,T}) where {S,T} = set!(x, zero(T))
