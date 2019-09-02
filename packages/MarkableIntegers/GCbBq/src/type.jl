abstract type MarkableUnsigned <: Unsigned end
abstract type MarkableSigned   <: Signed   end

const MarkableInteger = Union{MarkableUnsigned, MarkableSigned}

primitive type MarkUInt128 <: MarkableUnsigned 128 end
primitive type MarkUInt64  <: MarkableUnsigned  64 end
primitive type MarkUInt32  <: MarkableUnsigned  32 end
primitive type MarkUInt16  <: MarkableUnsigned  16 end
primitive type MarkUInt8   <: MarkableUnsigned   8 end

primitive type MarkInt128 <: MarkableSigned 128 end
primitive type MarkInt64  <: MarkableSigned  64 end
primitive type MarkInt32  <: MarkableSigned  32 end
primitive type MarkInt16  <: MarkableSigned  16 end
primitive type MarkInt8   <: MarkableSigned   8 end

if Int64 === Int
    const MarkInt  = MarkInt64
    const MarkUInt = MarkUInt64
else
    const MarkInt  = MarkInt32
    const MarkUInt = MarkUInt32
end


for (RU,U,RS,S) in (
    (:MarkUInt128, :UInt128, :MarkInt128, :Int128),
    (:MarkUInt64, :UInt64, :MarkInt64, :Int64),
    (:MarkUInt32, :UInt32, :MarkInt32, :Int32),
    (:MarkUInt16, :UInt16, :MarkInt16, :Int16),
    (:MarkUInt8, :UInt8, :MarkInt8, :Int8) )
  @eval begin

    function $RS(x::$S)
        !((typemin($S) >> 1) <= x <= (typemax($S) >> 1)) && throw(DomainError("$x"))
        x <<= 1
        z = reinterpret($RS, x)
        return z
    end

    function $RU(x::$U)
        x <= (typemax($U) >> 1) ?
        reinterpret($RU, (x << 1)) :
        throw(DomainError("$x"))
    end

    function $RS(x::$U)
        x <= (typemax($U) >> 2) ?
        reinterpret($RU, (x << 1)) :
        throw(DomainError("$x"))
    end

    function $RU(x::$S)
        zero($S) <= x <= (typemax($S) >> 1) ?
        reinterpret($RU, (x << 1)) :
        throw(DomainError("$x"))
    end

    $RU(x::$RU) = x
    $RS(x::$RS) = x
    $U(x::$RU) = reinterpret($U, x) >> 1
    $S(x::$RS) = reinterpret($S, x) >> 1
    $U(x::$RS) = $U(reinterpret($S, x) >> 1)
    $S(x::$RU) = $S(reinterpret($U, x) >> 1)

    Signed(x::$RS) = $S(x)
    Unsigned(x::$RU) = $U(x)
    Integer(x::$RS) = $S(x)
    Integer(x::$RU) = $U(x)
  end
end


function Marked(x::I) where {I<:Union{Signed,Unsigned}}
    T = mtype(I)
    z = T(x)
    z |= lsbit(T)
    return z
end

function Marked(x::I) where {I<:MarkableInteger}
    x |= lsbit(I)
    return x
end

function Unmarked(x::I) where {I<:Union{Signed,Unsigned}}
    T = mtype(I)
    z = T(x)
    return z
end

@inline function Unmarked(x::M) where {M<:MarkableInteger}
    return reinterpret(M, msbitsof(x))
end

Integer(x::M) where {M<:MarkableSigned} = Signed(x)
Integer(x::M) where {M<:MarkableUnsigned} = Unsigned(x)

"""
   Unmarked(x<:Signed)   ⇢ x<:MarkableSigned    && isunmarked(x)
   Unmarked(x<:Unsigned) ⇢ x<:MarkableUnsigned  && isunmarked(x)

```julia
three = 3
3
unmarked_three = Unmarked(three)
3
isunmarked(unmarked_three)
true
!ismarked(unmarked_three)
true
```
""" Unmarked

"""
   Marked(x<:Signed)   ⇢ x<:MarkableSigned    && ismarked(x)
   Marked(x<:Unsigned) ⇢ x<:MarkableUnsigned  && ismarked(x)

```julia
three = 3
3
marked_three = Marked(three)
3
ismarked(marked_three)
true
!isunmarked(marked_three)
true
```
""" Marked
