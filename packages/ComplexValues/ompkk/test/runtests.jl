using ComplexValues
const Spherical = ComplexValues.Spherical
const Polar = ComplexValues.Polar

using Test

@testset "Constructions of Polar" begin
	@test Polar(-5+1im) isa Number
	@test Polar(1.0im) isa Number
	@test Polar(-2) isa Number
	@test Polar(10.0f0) isa Number
	@test Polar(2.0f0,pi) isa Number
	@test Polar(pi,pi) isa Number
end

@testset "Constructions of Spherical" begin
	@test Spherical(-5+1im) isa Number
	@test Spherical(1.0im) isa Number
	@test Spherical(-2) isa Number
	@test Spherical(10.0f0) isa Number
	@test Spherical(2.0f0,pi) isa Number
	@test Spherical(pi/2,pi) isa Number
	@test S2coord(Spherical(1)) ≈ [1,0,0]
end

@testset "Conversions between Polar, Spherical" begin 
	for z in [-5+1im,1.0im,-2,10f0,Polar(Inf,-pi/5),Spherical(1,.5)]
		@test Polar(Spherical(z)) ≈ z
	end
	for z in [-5+1im,1.0im,-2,10f0]
		@test Polar{Float64}(Spherical{Float64}(z)) ≈ z
	end
end

@testset "Conversions in and out of Complex" begin 
	for z in [-5+1im,1.0im,-2,10f0,Polar(Inf,-pi/5),Spherical(1,.5)]
		@test Polar(Complex(z)) ≈ Polar(z)
		@test Complex(Polar(z)) ≈ Complex(z)
		@test Spherical(Complex(z)) ≈ Spherical(z)
		@test Complex(Spherical(z)) ≈ Complex(z)
	end
end

@testset "Zero and infinity for $T" for T in [Polar,Spherical]
    z = T(Inf)
    @test isinf(z)
    @test isinf(abs(z))
    @test iszero(1/z)
    @test iszero(abs(inv(z)))
    @test iszero(Complex(4/z))
    z = T(0)
    @test iszero(z)
    @test isinf(3im/z)
    z = zero(T)
    @test iszero(z)
    @test isinf(3im/z)
end

@testset "Binary functions on $S,$T" for S in [Polar,Spherical], T in [Polar,Spherical]
	u = S(3.0+5.0im)
	v = T(-5+1im)
	@test Complex(u+v) ≈ Complex(u)+Complex(v)
	@test Complex(u*v) ≈ Complex(u)*Complex(v)
	@test Complex(u/v) ≈ Complex(u)/Complex(v)
	@test Complex(u-v) ≈ Complex(u)-Complex(v)
	@test Complex(u^v) ≈ Complex(u)^Complex(v)
end

@testset "Unary functions on $T" for T in [Polar,Spherical]
    u = T(3.0+5.0im)
    @test Complex(u-4) ≈ Complex(u)-4
    @test Complex(4-u) ≈ 4-Complex(u)
    @test Complex(cos(exp(u))) ≈ cos(exp(Complex(u)))
    @test Complex(sqrt(inv(u))) ≈ sqrt(inv(Complex(u)))
end
