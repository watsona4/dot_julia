using YaoExtensions
using Yao, SymEngine
using Test

@testset "gate count, time" begin
    qc = QFTCircuit(3)
    @test qc |> gatecount |> length == 2
    @test qc |> gatecount |> values |> sum == 6
    @vars T1 T2
    ex = chain(qc, Wait{3}(0.1)) |> gatetime
    @test subs(ex, T1=>1,T2=>10) == 33.1
end
