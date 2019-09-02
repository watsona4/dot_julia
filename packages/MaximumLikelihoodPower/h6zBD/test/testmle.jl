@testset "scanmle KS statistic" begin
    seed = 11
    α = 0.5
    data = Example.makeparetodata(α, seed)
    @test MLE.scanKS(data, range(.4, length=11, stop=.6)) == [0.48, 0.5, 0.52]
    @test abs(MLE.scanmle(data).alpha - 1.5) < 1e-2
end
