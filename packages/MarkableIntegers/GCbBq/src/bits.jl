@inline bitor(x,y) = Base.:(|)(x,y)
@inline bitand(x,y) = Base.:(&)(x,y)
@inline bitxor(x,y) = Base.:(⊻)(x,y)
@inline bitor(x,y,z) = bitor(x,bitor(y,z))
@inline bitand(x,y,z) = bitand(x,bitand(y,z))
@inline bitor(w,x,y,z) = bitor(bitor(w,x),bitor(y,z))
@inline bitand(w,x,y,z) = bitand(bitand(w,x),bitand(y,z))

# bitsof is like sizeof

bitsof(::Type{UInt8})   =   8
bitsof(::Type{UInt16})  =  16
bitsof(::Type{UInt32})  =  32
bitsof(::Type{UInt64})  =  64
bitsof(::Type{UInt128}) = 128
bitsof(::Type{Int8})    =   8
bitsof(::Type{Int16})   =  16
bitsof(::Type{Int32})   =  32
bitsof(::Type{Int64})   =  64
bitsof(::Type{Int128})  = 128

bitsof(x::U) where {U<:Unsigned} = bitsof(U)
bitsof(x::S) where {S<:Signed} = bitsof(S)

# with Markables, one bit is reserved for marking

bitsof(::Type{MarkUInt8})   =   7
bitsof(::Type{MarkUInt16})  =  15
bitsof(::Type{MarkUInt32})  =  31
bitsof(::Type{MarkUInt64})  =  63
bitsof(::Type{MarkUInt128}) = 127
bitsof(::Type{MarkInt8})    =   7
bitsof(::Type{MarkInt16})   =  15
bitsof(::Type{MarkInt32})   =  31
bitsof(::Type{MarkInt64})   =  63
bitsof(::Type{MarkInt128})  = 127

bitsof(x::U) where {U<:MarkableUnsigned} = bitsof(U)
bitsof(x::S) where {S<:MarkableSigned} = bitsof(S)

# lsbit(T) is used to mask the least significant bit of x::T

lsbit(::Type{UInt8})    = 0x01
lsbit(::Type{UInt16})   = 0x0001
lsbit(::Type{UInt32})   = 0x00000001
lsbit(::Type{UInt64})   = 0x0000000000000001
lsbit(::Type{UInt128})  = 0x00000000000000000000000000000001
lsbit(::Type{Int8})     = 0x01%Int8
lsbit(::Type{Int16})    = 0x0001%Int16
lsbit(::Type{Int32})    = 0x00000001%Int32
lsbit(::Type{Int64})    = 0x0000000000000001%Int64
lsbit(::Type{Int128})   = 0x00000000000000000000000000000001%Int128

lsbit(::Type{MarkUInt8})    = reinterpret(MarkUInt8, 0x01)
lsbit(::Type{MarkUInt16})   = reinterpret(MarkUInt16, 0x0001)
lsbit(::Type{MarkUInt32})   = reinterpret(MarkUInt32, 0x00000001)
lsbit(::Type{MarkUInt64})   = reinterpret(MarkUInt64, 0x0000000000000001)
lsbit(::Type{MarkUInt128})  = reinterpret(MarkUInt128, 0x00000000000000000000000000000001)
lsbit(::Type{MarkInt8})     = reinterpret(MarkInt8, 0x01)
lsbit(::Type{MarkInt16})    = reinterpret(MarkInt16, 0x0001)
lsbit(::Type{MarkInt32})    = reinterpret(MarkInt32, 0x00000001)
lsbit(::Type{MarkInt64})    = reinterpret(MarkInt64, 0x0000000000000001)
lsbit(::Type{MarkInt128})   = reinterpret(MarkInt128, 0x00000000000000000000000000000001)

# msbits(T) is used to mask all but the least significant bit of x::T

msbits(::Type{UInt8})    = 0xfe      # (-one(Int8))%UInt8 << 1
msbits(::Type{UInt16})   = 0xfffe
msbits(::Type{UInt32})   = 0xfffffffe
msbits(::Type{UInt64})   = 0xfffffffffffffffe
msbits(::Type{UInt128})  = 0xfffffffffffffffffffffffffffffffe
msbits(::Type{Int8})     = 0xfe%Int8
msbits(::Type{Int16})    = 0xfffe%Int16
msbits(::Type{Int32})    = 0xfffffffe%Int32
msbits(::Type{Int64})    = 0xfffffffffffffffe%Int64
msbits(::Type{Int128})   = 0xfffffffffffffffffffffffffffffffe%Int128

msbits(::Type{MarkUInt8})    = reinterpret(MarkUInt8, 0xfe)      # (-one(Int8))%UInt8 << 1
msbits(::Type{MarkUInt16})   = reinterpret(MarkUInt16, 0xfffe)
msbits(::Type{MarkUInt32})   = reinterpret(MarkUInt32, 0xfffffffe)
msbits(::Type{MarkUInt64})   = reinterpret(MarkUInt64, 0xfffffffffffffffe)
msbits(::Type{MarkUInt128})  = reinterpret(MarkUInt128, 0xfffffffffffffffffffffffffffffffe)
msbits(::Type{MarkInt8})     = reinterpret(MarkInt8, 0xfe)
msbits(::Type{MarkInt16})    = reinterpret(MarkInt16, 0xfffe)
msbits(::Type{MarkInt32})    = reinterpret(MarkInt32, 0xfffffffe)
msbits(::Type{MarkInt64})    = reinterpret(MarkInt64, 0xfffffffffffffffe)
msbits(::Type{MarkInt128})   = reinterpret(MarkInt128, 0xfffffffffffffffffffffffffffffffe)

# for isolation of mark, nomark bits
@inline lsbitof(x::T) where {T<:MarkableInteger}  =
    bitand(reinterpret(itype(T),x), lsbit(itype(T)))
@inline msbitsof(x::T) where {T<:MarkableInteger} =
    bitand(reinterpret(itype(T),x), msbits(itype(T)))
@inline lsbitof(x::T) where {T<:Union{Signed,Unsigned}}  =
    bitand(x, lsbit(itype(T)))
@inline msbitsof(x::T) where {T<:Union{Signed,Unsigned}} =
    bitand(x, msbits(itype(T)))

# for propogation of marks through operations
@inline any_lsbits(a::T) where {T<:MarkableInteger} = lsbitof(a)
@inline all_lsbits(a::T) where {T<:MarkableInteger} = lsbitof(a)
@inline any_lsbits(a::T, b::T) where {T<:MarkableInteger} = lsbitof(a) | lsbitof(b)
@inline all_lsbits(a::T, b::T) where {T<:MarkableInteger} = lsbitof(a) & lsbitof(b)
any_lsbits(a::T, b::T, c::T) where {T<:MarkableInteger} = bitor(lsbitof(a), lsbitof(b), lsbitof(c))
all_lsbits(a::T, b::T, c::T) where {T<:MarkableInteger} = bitand(lsbitof(a), lsbitof(b), lsbitof(c))
any_lsbits(a::T, b::T, c::T, d::T) where {T<:MarkableInteger} = bitand(lsbitof(a), lsbitof(b), lsbitof(c), lsbitof(d))
all_lsbits(a::T, b::T, c::T, d::T) where {T<:MarkableInteger} = bitand(lsbitof(a), lsbitof(b), lsbitof(c), lsbitof(d))

any_lsbits(a::T1, b::T2) where {T1<:MarkableInteger, T2<:MarkableInteger} = any_lsbits(promote(a,b)...,)
all_lsbits(a::T1, b::T2) where {T1<:MarkableInteger, T2<:MarkableInteger} = all_lsbits(promote(a,b)...,)
