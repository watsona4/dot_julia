using Destruct
using Compat.Test
using Compat.Random
import Compat.rand

rand(rng::AbstractRNG, T::Type{String}) = randstring(rng)
types = [Int32, Float64, Complex{Float64}, Bool]

@testset "NTuple" begin
for T=types, N=[1,2,3,4,5]
    sz = fill(5, N)
    a = rand(T, sz...); b = rand(T, sz...); z = collect(zip(a,b))
    @assert size(z) == size(a) # make sure collect preserved array shape
    @test (a,b) == destruct(z)
end end

@testset "Tuple" begin
for T1=types, T2=types, N=[1,2,3]
    sz = fill(3,N)
    a = rand(T1, sz...); b = rand(T2, sz...); z = collect(zip(a,b))
    @assert size(z) == size(a) # make sure collect preserved array shape
    @test (a,b) == destruct(z)
end end

@testset "Tuple, Non square" begin
for T1=types, T2=types, N=[2,3]
    sz = 2:N+1
    a = rand(T1, sz...); b = rand(T2, sz...); z = collect(zip(a,b))
    @assert size(z) == size(a) # make sure collect preserved array shape
    @test (a,b) == destruct(z)
end end
