using ApproxFunOrthogonalPolynomials, InfiniteArrays, LinearAlgebra, Test

@testset "Domain" begin
    @test reverseorientation(Arc(1,2,(0.1,0.2))) == Arc(1,2,(0.2,0.1))
end

@time include("ClenshawTest.jl")
@time include("ChebyshevTest.jl")
@time include("ComplexTest.jl")
@time include("broadcastingtest.jl")
@time include("OperatorTest.jl")
@time include("ODETest.jl")
@time include("EigTest.jl")
@time include("VectorTest.jl")
@time include("JacobiTest.jl")
@time include("LaguerreTest.jl")
@time include("HermiteTest.jl")
@time include("SpacesTest.jl")
@time include("MultivariateTest.jl")
@time include("PDETest.jl")

include("SpeedTest.jl")
include("SpeedODETest.jl")
include("SpeedPDETest.jl")
include("SpeedOperatorTest.jl")
