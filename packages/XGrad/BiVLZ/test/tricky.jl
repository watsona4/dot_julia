
@testset "tricky" begin

    x = [2.0, 4.0, 6.0]
    myfirst(x) = x[1]
    
    @test xgrad(myfirst; x=x) == (2.0, [1.0, 0.0, 0.0])
    
end
