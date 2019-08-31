@testset "dec_exp" begin
    dec_exp = Beauty.dec_exp
    @test dec_exp(1.1) == 0
    @test dec_exp(9.99) == 0
    @test dec_exp(11.0) == 1
    @test dec_exp(99.99) == 1
    @test dec_exp(110.0) == 2
    @test dec_exp(0.11) == -1
    @test dec_exp(0.011) == -2
end
