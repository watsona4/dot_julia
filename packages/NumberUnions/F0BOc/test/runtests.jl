using NumberUnions

if VERSION >= v"0.7-"
    using Test
else
    using Base.Test
end

@test Float64 <: IntFloat64 
@test Int64 <: IntFloat64
@test !(Float64 <: IntFloat32) 

@test SysInt >: Int16
@test Integer32 == Union{Int32, UInt32}

@test bytes2Int( sizeof(Int16) ) === Int16
@test bytes2UInt( sizeof(UInt32) ) === UInt32
@test bytes2Float( sizeof(Float64) ) === Float64
