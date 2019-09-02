promote_rule(::Type{MarkInt128}, ::Type{MarkInt64}) = MarkInt128
promote_rule(::Type{MarkInt128}, ::Type{MarkInt32}) = MarkInt128
promote_rule(::Type{MarkInt128}, ::Type{MarkInt16}) = MarkInt128
promote_rule(::Type{MarkInt128}, ::Type{MarkInt8}) = MarkInt128
promote_rule(::Type{MarkInt64}, ::Type{MarkInt32}) = MarkInt64
promote_rule(::Type{MarkInt64}, ::Type{MarkInt16}) = MarkInt64
promote_rule(::Type{MarkInt64}, ::Type{MarkInt8}) = MarkInt64
promote_rule(::Type{MarkInt32}, ::Type{MarkInt16}) = MarkInt32
promote_rule(::Type{MarkInt32}, ::Type{MarkInt8}) = MarkInt32
promote_rule(::Type{MarkInt16}, ::Type{MarkInt8}) = MarkInt16

convert(::Type{MarkInt128}, x::MarkInt64) = isunmarked(x) ? reinterpret(MarkInt128, Int128(ityped(x)>>1)<<1) : mark(reinterpret(MarkInt128, Int128(ityped(x)>>1)<<1))
convert(::Type{MarkInt128}, x::MarkInt32) = isunmarked(x) ? reinterpret(MarkInt128, Int128(ityped(x)>>1)<<1) : mark(reinterpret(MarkInt128, Int128(ityped(x)>>1)<<1))
convert(::Type{MarkInt128}, x::MarkInt16) = isunmarked(x) ? reinterpret(MarkInt128, Int128(ityped(x)>>1)<<1) : mark(reinterpret(MarkInt128, Int128(ityped(x)>>1)<<1))
convert(::Type{MarkInt128}, x::MarkInt8) = isunmarked(x) ? reinterpret(MarkInt128, Int128(ityped(x)>>1)<<1) : mark(reinterpret(MarkInt128, Int128(ityped(x)>>1)<<1))
convert(::Type{MarkInt64}, x::MarkInt32) = isunmarked(x) ? reinterpret(MarkInt64, Int64(ityped(x)>>1)<<1) : mark(reinterpret(MarkInt64, Int64(ityped(x)>>1)<<1))
convert(::Type{MarkInt64}, x::MarkInt16) = isunmarked(x) ? reinterpret(MarkInt64, Int64(ityped(x)>>1)<<1) : mark(reinterpret(MarkInt64, Int64(ityped(x)>>1)<<1))
convert(::Type{MarkInt64}, x::MarkInt8) = isunmarked(x) ? reinterpret(MarkInt64, Int64(ityped(x)>>1)<<1) : mark(reinterpret(MarkInt64, Int64(ityped(x)>>1)<<1))
convert(::Type{MarkInt32}, x::MarkInt16) = isunmarked(x) ? reinterpret(MarkInt32, Int32(ityped(x)>>1)<<1) : mark(reinterpret(MarkInt32, Int32(ityped(x)>>1)<<1))
convert(::Type{MarkInt32}, x::MarkInt8) = isunmarked(x) ? reinterpret(MarkInt32, Int32(ityped(x)>>1)<<1) : mark(reinterpret(MarkInt32, Int32(ityped(x)>>1)<<1))
convert(::Type{MarkInt16}, x::MarkInt8) = isunmarked(x) ? reinterpret(MarkInt16, Int16(ityped(x)>>1)<<1) : mark(reinterpret(MarkInt16, Int16(ityped(x)>>1)<<1))

promote_rule(::Type{MarkUInt128}, ::Type{MarkUInt64}) = MarkUInt128
promote_rule(::Type{MarkUInt128}, ::Type{MarkUInt32}) = MarkUInt128
promote_rule(::Type{MarkUInt128}, ::Type{MarkUInt16}) = MarkUInt128
promote_rule(::Type{MarkUInt128}, ::Type{MarkUInt8}) = MarkUInt128
promote_rule(::Type{MarkUInt64}, ::Type{MarkUInt32}) = MarkUInt64
promote_rule(::Type{MarkUInt64}, ::Type{MarkUInt16}) = MarkUInt64
promote_rule(::Type{MarkUInt64}, ::Type{MarkUInt8}) = MarkUInt64
promote_rule(::Type{MarkUInt32}, ::Type{MarkUInt16}) = MarkUInt32
promote_rule(::Type{MarkUInt32}, ::Type{MarkUInt8}) = MarkUInt32
promote_rule(::Type{MarkUInt16}, ::Type{MarkUInt8}) = MarkUInt16


convert(::Type{MarkUInt128}, x::MarkUInt64) = isunmarked(x) ? reinterpret(MarkUInt128, UInt128(ityped(x)>>1)<<1) : mark(reinterpret(MarkUInt128, UInt128(ityped(x)>>1)<<1))
convert(::Type{MarkUInt128}, x::MarkUInt32) = isunmarked(x) ? reinterpret(MarkUInt128, UInt128(ityped(x)>>1)<<1) : mark(reinterpret(MarkUInt128, UInt128(ityped(x)>>1)<<1))
convert(::Type{MarkUInt128}, x::MarkUInt16) = isunmarked(x) ? reinterpret(MarkUInt128, UInt128(ityped(x)>>1)<<1) : mark(reinterpret(MarkUInt128, UInt128(ityped(x)>>1)<<1))
convert(::Type{MarkUInt128}, x::MarkUInt8) = isunmarked(x) ? reinterpret(MarkUInt128, UInt128(ityped(x)>>1)<<1) : mark(reinterpret(MarkUInt128, UInt128(ityped(x)>>1)<<1))
convert(::Type{MarkUInt64}, x::MarkUInt32) = isunmarked(x) ? reinterpret(MarkUInt64, UInt64(ityped(x)>>1)<<1) : mark(reinterpret(MarkUInt64, UInt64(ityped(x)>>1)<<1))
convert(::Type{MarkUInt64}, x::MarkUInt16) = isunmarked(x) ? reinterpret(MarkUInt64, UInt64(ityped(x)>>1)<<1) : mark(reinterpret(MarkUInt64, UInt64(ityped(x)>>1)<<1))
convert(::Type{MarkUInt64}, x::MarkUInt8) = isunmarked(x) ? reinterpret(MarkUInt64, UInt64(ityped(x)>>1)<<1) : mark(reinterpret(MarkUInt64, UInt64(ityped(x)>>1)<<1))
convert(::Type{MarkUInt32}, x::MarkUInt16) = isunmarked(x) ? reinterpret(MarkUInt32, UInt32(ityped(x)>>1)<<1) : mark(reinterpret(MarkUInt32, UInt32(ityped(x)>>1)<<1))
convert(::Type{MarkUInt32}, x::MarkUInt8) = isunmarked(x) ? reinterpret(MarkUInt32, UInt32(ityped(x)>>1)<<1) : mark(reinterpret(MarkUInt32, UInt32(ityped(x)>>1)<<1))
convert(::Type{MarkUInt16}, x::MarkUInt8) = isunmarked(x) ? reinterpret(MarkUInt16, UInt16(ityped(x)>>1)<<1) : mark(reinterpret(MarkUInt16, UInt16(ityped(x)>>1)<<1))

promote_rule(::Type{MarkInt128}, ::Type{Int128}) = MarkInt128
promote_rule(::Type{MarkInt128}, ::Type{Int64}) = MarkInt128
promote_rule(::Type{MarkInt128}, ::Type{Int32}) = MarkInt128
promote_rule(::Type{MarkInt128}, ::Type{Int16}) = MarkInt128
promote_rule(::Type{MarkInt128}, ::Type{Int8}) = MarkInt128
promote_rule(::Type{MarkInt64}, ::Type{Int64}) = MarkInt64
promote_rule(::Type{MarkInt64}, ::Type{Int32}) = MarkInt64
promote_rule(::Type{MarkInt64}, ::Type{Int16}) = MarkInt64
promote_rule(::Type{MarkInt64}, ::Type{Int8}) = MarkInt64
promote_rule(::Type{MarkInt32}, ::Type{Int32}) = MarkInt32
promote_rule(::Type{MarkInt32}, ::Type{Int16}) = MarkInt32
promote_rule(::Type{MarkInt32}, ::Type{Int8}) = MarkInt32
promote_rule(::Type{MarkInt16}, ::Type{Int16}) = MarkInt16
promote_rule(::Type{MarkInt16}, ::Type{Int8}) = MarkInt16
promote_rule(::Type{MarkInt8}, ::Type{Int8}) = MarkInt8

convert(::Type{MarkInt128}, x::Int128) = Unmarked(x)
convert(::Type{MarkInt128}, x::Int64) = Unmarked(Int128(x))
convert(::Type{MarkInt128}, x::Int32) = Unmarked(Int128(x))
convert(::Type{MarkInt128}, x::Int16) = Unmarked(Int128(x))
convert(::Type{MarkInt128}, x::Int8) = Unmarked(Int128(x))
convert(::Type{MarkInt64}, x::Int64) = Unmarked(x)
convert(::Type{MarkInt64}, x::Int32) = Unmarked(Int64(x))
convert(::Type{MarkInt64}, x::Int16) = Unmarked(Int64(x))
convert(::Type{MarkInt64}, x::Int8) = Unmarked(Int64(x))
convert(::Type{MarkInt32}, x::Int32) = Unmarked(x)
convert(::Type{MarkInt32}, x::Int16) = Unmarked(Int32(x))
convert(::Type{MarkInt32}, x::Int8) = Unmarked(Int32(x))
convert(::Type{MarkInt16}, x::Int16) = Unmarked(x)
convert(::Type{MarkInt16}, x::Int8) = Unmarked(Int16(x))
convert(::Type{MarkInt8}, x::Int8) = Unmarked(x)

promote_rule(::Type{MarkUInt128}, ::Type{UInt128}) = MarkUInt128
promote_rule(::Type{MarkUInt128}, ::Type{UInt64}) = MarkUInt128
promote_rule(::Type{MarkUInt128}, ::Type{UInt32}) = MarkUInt128
promote_rule(::Type{MarkUInt128}, ::Type{UInt16}) = MarkUInt128
promote_rule(::Type{MarkUInt128}, ::Type{UInt8}) = MarkUInt128
promote_rule(::Type{MarkUInt64}, ::Type{UInt64}) = MarkUInt64
promote_rule(::Type{MarkUInt64}, ::Type{UInt32}) = MarkUInt64
promote_rule(::Type{MarkUInt64}, ::Type{UInt16}) = MarkUInt64
promote_rule(::Type{MarkUInt64}, ::Type{UInt8}) = MarkUInt64
promote_rule(::Type{MarkUInt32}, ::Type{UInt32}) = MarkUInt32
promote_rule(::Type{MarkUInt32}, ::Type{UInt16}) = MarkUInt32
promote_rule(::Type{MarkUInt32}, ::Type{UInt8}) = MarkUInt32
promote_rule(::Type{MarkUInt16}, ::Type{UInt16}) = MarkUInt16
promote_rule(::Type{MarkUInt16}, ::Type{UInt8}) = MarkUInt16
promote_rule(::Type{MarkUInt8}, ::Type{UInt8}) = MarkUInt8

convert(::Type{MarkUInt128}, x::UInt128) = Unmarked(x)
convert(::Type{MarkUInt128}, x::UInt64) = Unmarked(UInt128(x))
convert(::Type{MarkUInt128}, x::UInt32) = Unmarked(UInt128(x))
convert(::Type{MarkUInt128}, x::UInt16) = Unmarked(UInt128(x))
convert(::Type{MarkUInt128}, x::UInt8) = Unmarked(UInt128(x))
convert(::Type{MarkUInt64}, x::UInt64) = Unmarked(x)
convert(::Type{MarkUInt64}, x::UInt32) = Unmarked(UInt64(x))
convert(::Type{MarkUInt64}, x::UInt16) = Unmarked(UInt64(x))
convert(::Type{MarkUInt64}, x::UInt8) = Unmarked(UInt64(x))
convert(::Type{MarkUInt32}, x::UInt32) = Unmarked(x)
convert(::Type{MarkUInt32}, x::UInt16) = Unmarked(UInt32(x))
convert(::Type{MarkUInt32}, x::UInt8) = Unmarked(UInt32(x))
convert(::Type{MarkUInt16}, x::UInt16) = Unmarked(x)
convert(::Type{MarkUInt16}, x::UInt8) = Unmarked(UInt16(x))
convert(::Type{MarkUInt8}, x::UInt8) = Unmarked(x)


MarkInt128(x::MarkInt64) = ismarked(x) ? Marked(Int128(itype(x))) : Unmarked(Int128(itype(x)))
MarkInt128(x::MarkInt32) = ismarked(x) ? Marked(Int128(itype(x))) : Unmarked(Int128(itype(x)))
MarkInt128(x::MarkInt16) = ismarked(x) ? Marked(Int128(itype(x))) : Unmarked(Int128(itype(x)))
MarkInt128(x::MarkInt8) = ismarked(x) ? Marked(Int128(itype(x))) : Unmarked(Int128(itype(x)))
MarkInt64(x::MarkInt32) = ismarked(x) ? Marked(Int64(itype(x))) : Unmarked(Int64(itype(x)))
MarkInt64(x::MarkInt16) = ismarked(x) ? Marked(Int64(itype(x))) : Unmarked(Int64(itype(x)))
MarkInt64(x::MarkInt8) = ismarked(x) ? Marked(Int64(itype(x))) : Unmarked(Int64(itype(x)))
MarkInt32(x::MarkInt16) = ismarked(x) ? Marked(Int32(itype(x))) : Unmarked(Int32(itype(x)))
MarkInt32(x::MarkInt8) = ismarked(x) ? Marked(Int32(itype(x))) : Unmarked(Int32(itype(x)))
MarkInt16(x::MarkInt8) = ismarked(x) ? Marked(Int16(itype(x))) : Unmarked(Int16(itype(x)))

MarkUInt128(x::MarkUInt64) = ismarked(x) ? Marked(UInt128(itype(x))) : Unmarked(UInt128(itype(x)))
MarkUInt128(x::MarkUInt32) = ismarked(x) ? Marked(UInt128(itype(x))) : Unmarked(UInt128(itype(x)))
MarkUInt128(x::MarkUInt16) = ismarked(x) ? Marked(UInt128(itype(x))) : Unmarked(UInt128(itype(x)))
MarkUInt128(x::MarkUInt8) = ismarked(x) ? Marked(UInt128(itype(x))) : Unmarked(UInt128(itype(x)))
MarkUInt64(x::MarkUInt32) = ismarked(x) ? Marked(UInt64(itype(x))) : Unmarked(UInt64(itype(x)))
MarkUInt64(x::MarkUInt16) = ismarked(x) ? Marked(UInt64(itype(x))) : Unmarked(UInt64(itype(x)))
MarkUInt64(x::MarkUInt8) = ismarked(x) ? Marked(UInt64(itype(x))) : Unmarked(UInt64(itype(x)))
MarkUInt32(x::MarkUInt16) = ismarked(x) ? Marked(UInt32(itype(x))) : Unmarked(UInt32(itype(x)))
MarkUInt32(x::MarkUInt8) = ismarked(x) ? Marked(UInt32(itype(x))) : Unmarked(UInt32(itype(x)))
MarkUInt16(x::MarkUInt8) = ismarked(x) ? Marked(UInt16(itype(x))) : Unmarked(UInt16(itype(x)))



MarkInt128(x::I) where {I<:Union{Int64, Int32, Int16, Int8}} = MarkInt128(Int128(x))
MarkUInt128(x::I) where {I<:Union{UInt64, UInt32, UInt16, UInt8}} = MarkUInt128(UInt128(x))
MarkInt64(x::I) where {I<:Union{Int32, Int16, Int8}} = MarkInt64(Int64(x))
MarkUInt64(x::I) where {I<:Union{UInt32, UInt16, UInt8}} = MarkUInt64(UInt64(x))
MarkInt32(x::I) where {I<:Union{Int16, Int8}} = MarkInt32(Int32(x))
MarkUInt32(x::I) where {I<:Union{UInt16, UInt8}} = MarkUInt32(UInt32(x))
MarkInt16(x::Int8) = MarkInt16(Int16(x))
MarkUInt16(x::UInt8) = MarkUInt16(UInt16(x))


convert(::Type{Int64}, x::Int128) = Int64(x)
convert(::Type{Int64}, x::Int64) = x
convert(::Type{Int64}, x::Int32) = Int64(x)
convert(::Type{Int64}, x::Int16) = Int64(x)
convert(::Type{Int64}, x::Int8) = Int64(x)
convert(::Type{Int32}, x::Int128) = Int32(x)
convert(::Type{Int32}, x::Int64) = Int32(x)
convert(::Type{Int32}, x::Int32) = x
convert(::Type{Int32}, x::Int16) = Int32(x)
convert(::Type{Int32}, x::Int8) = Int32(x)
convert(::Type{Int16}, x::Int128) = Int16(x)
convert(::Type{Int16}, x::Int64) = Int16(x)
convert(::Type{Int16}, x::Int32) = Int16(x)
convert(::Type{Int16}, x::Int16) = x
convert(::Type{Int16}, x::Int8) = Int16(x)


convert(::Type{UInt64}, x::UInt128) = UInt64(x)
convert(::Type{UInt64}, x::UInt64) = x
convert(::Type{UInt64}, x::UInt32) = UInt64(x)
convert(::Type{UInt64}, x::UInt16) = UInt64(x)
convert(::Type{UInt64}, x::UInt8) = UInt64(x)
convert(::Type{UInt32}, x::UInt128) = UInt32(x)
convert(::Type{UInt32}, x::UInt64) = UInt32(x)
convert(::Type{UInt32}, x::UInt32) = x
convert(::Type{UInt32}, x::UInt16) = UInt32(x)
convert(::Type{UInt32}, x::UInt8) = UInt32(x)
convert(::Type{UInt16}, x::UInt128) = UInt16(x)
convert(::Type{UInt16}, x::UInt64) = UInt16(x)
convert(::Type{UInt16}, x::UInt32) = UInt16(x)
convert(::Type{UInt16}, x::UInt16) = x
convert(::Type{UInt16}, x::UInt8) = UInt16(x)
