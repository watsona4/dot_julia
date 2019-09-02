module NumberUnions

export IEEEFloat,
       MachInt, MachUInt, MachFloat,
       SysInt, SysUInt, SysFloat,
       Integer128, Integer64, Integer32, Integer8,
       IntFloat64, IntFloat32, IntFloat16,
       bytes2Int, bytes2UInt, bytes2Float

import Base: IEEEFloat

const MachInt   = Union{   Int64,   Int32 } 
const MachUInt  = Union{  UInt64,  UInt32 } 
const MachFloat = Union{ Float64, Float32 } 

const IntFloat64  = Union{ Int64, Float64 } 
const IntFloat32  = Union{ Int32, Float32 } 
const IntFloat16  = Union{ Int16, Float16 } 

const SysInt   = Union{ Int128,   Int64,   Int32,  Int16,  Int8 } 
const SysUInt  = Union{ UInt128, UInt64,  UInt32, UInt16, UInt8 } 
const SysFloat = Union{ Float64, Float32, Float16 } 

const Integer128 = Union{ Int128, UInt128 } 
const Integer64  = Union{ Int64, UInt64 } 
const Integer32  = Union{ Int32, UInt32 } 
const Integer16  = Union{ Int16, UInt16 } 
const Integer8   = Union{ Int8, UInt8 } 


"""
   lookup primitive numeric {Int, UInt, Float} type using sizeof(type)

```julia

indexbysize(nbytes) = 1 + (nbytes >> 1) - (nbytes >> 3) - ((nbytes >> 4) << 1);

floatsizes = (sizeof(Float16), sizeof(Float32), sizeof(Float64))
(2, 4, 8)

indices_for_float_types =  [indexbysize(nbytes) for nbytes in floatsizes];

SysFloatsBySize[ indices_for_float_types ] == [Float16, Float32, Float64]
true

intsizes = (sizeof(Int8), sizeof(Int16), sizeof(Int32), sizeof(Int64), sizeof(Int128))
(1, 2, 4, 8, 16)

indices_for_int_types =  [indexbysize(nbytes) for nbytes in intsizes];

SysIntsBySize[ indicies_for_int_types ] == [Int8,    Int16,   Int32,   Int64,   Int128]
true
```
""" bytes2Int, bytes2UInt, bytes2Float

const SysIntSizes   = [ Int8,    Int16,   Int32,   Int64,   Int128  ]
const SysUIntSizes  = [ UInt8,   UInt16,  UInt32,  UInt64,  UInt128 ]
const SysFloatSizes = [ Float16, Float16, Float32, Float64, Float64 ]

@inline indexbysize(nbytes) = 1 + (nbytes >> 1) - (nbytes >> 3) - ((nbytes >> 4) << 1)

bytes2Int(nbytes) = SysIntSizes[ indexbysize(nbytes) ]
bytes2UInt(nbytes) = SysUIntSizes[ indexbysize(nbytes) ]
bytes2Float(nbytes) = SysFloatSizes[ indexbysize(nbytes) ]

end # module
