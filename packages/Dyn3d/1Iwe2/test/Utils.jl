@testset "Utils" begin
    @testset "get" begin
        z = rand(ComplexF64)

        @getfield z (im, re)
        @test im == imag(z)
        @test re == real(z)

        @getfield z (re, im)
        @test im == imag(z)
        @test re == real(z)

        @getfield z (re, im) (r, i)
        @test i == imag(z)
        @test r == real(z)
end

end
