using Yao
using Test
using YaoExtensions
using YaoBlocks: ConstGate

@testset "solving hamiltonian" begin
    nbit = 8
    h = heisenberg(nbit) |> cache
    @test ishermitian(h)
end
