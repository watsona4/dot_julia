using QNaNs
using Test

@test isnan(qnan(Int64(3))) == true
@test isnan(qnan(Int32(3))) == true
@test isnan(qnan(Int16(3))) == true

@test typeof(qnan(Int64(5))) == Float64
@test typeof(qnan(Int32(5))) == Float32
@test typeof(qnan(Int16(5))) == Float16

@test qnan(qnan(Int64(17))) == 17
@test qnan(qnan(Int32(17))) == 17
@test qnan(qnan(Int16(17))) == 17

@test qnan(qnan(Int64(-22))) == -22
@test qnan(qnan(Int32(-22))) == -22
@test qnan(qnan(Int16(-22))) == -22

@test qnan(zero(Int64)) === NaN
@test qnan(zero(Int32)) === NaN32
