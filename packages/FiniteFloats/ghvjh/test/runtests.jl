using FiniteFloats
using Test

@test isfinite(Finite64(Inf))
@test isfinite(Finite32(-Inf32))
@test isfinite(Finite16(Inf16))

