@testset "Util" begin
    @testset "Perpendicular vector" begin
        for i = 1 : 100
            vec = randn(SVector{3, Float64})
            perp = Rotations.perpendicular_vector(vec)
            @test norm(perp) >= maximum(abs.(vec))
            @test isapprox(dot(vec, perp), 0.; atol = 1e-10)
        end
        let vec = randn(SVector{3, Float64})
            allocs = @allocated Rotations.perpendicular_vector(vec)
            @test allocs == 0
        end
    end
end
