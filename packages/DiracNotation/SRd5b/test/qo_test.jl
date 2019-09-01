using QuantumOptics

@testset "QuantumOptics" begin

    Random.seed!(0)
    b = SpinBasis(1//2)
    psi0 = spinup(b)
    psi1 = spindown(b)

    @test sprint((io, x) -> dirac(io, x, header=true), psi0) == "Ket(dim=2)\n  basis: Spin(1/2)\n|ψ⟩ = |0⟩\n"
    @test sprint((io, x) -> dirac(io, x, header=true), psi1) == "Ket(dim=2)\n  basis: Spin(1/2)\n|ψ⟩ = |1⟩\n"
    @test sprint((io, x) -> dirac(io, x, header=true), psi0 ⊗ psi1) == "Ket(dim=4)\n  basis: [Spin(1/2) ⊗ Spin(1/2)]\n|ψ⟩ = |10⟩\n"
    @test sprint((io, x) -> dirac(io, x, header=true), psi1 ⊗ psi0) == "Ket(dim=4)\n  basis: [Spin(1/2) ⊗ Spin(1/2)]\n|ψ⟩ = |01⟩\n"
    @test sprint((io, x) -> dirac(io, x, header=false), psi0) == "|ψ⟩ = |0⟩\n"
    @test sprint((io, x) -> dirac(io, x, header=false), psi1) == "|ψ⟩ = |1⟩\n"
    @test sprint((io, x) -> dirac(io, x, header=false), psi0 ⊗ psi1) == "|ψ⟩ = |10⟩\n"
    @test sprint((io, x) -> dirac(io, x, header=false), psi1 ⊗ psi0) == "|ψ⟩ = |01⟩\n"

    @show psi = randstate(b)
    @show psi ⊗ dagger(psi)
    @test sprint((io, x) -> dirac(io, x, header=true), psi) == "Ket(dim=2)\n  basis: Spin(1/2)\n|ψ⟩ = (0.65825+0.727547im)|0⟩+(0.131519+0.141719im)|1⟩\n"
    @test sprint((io, x) -> dirac(io, x, header=true), psi ⊗ dagger(psi)) == "DenseOperator(dim=2x2)\n  basis: Spin(1/2)\nρ = 0.962618|0⟩⟨0|+(0.18968+0.00239967im)|0⟩⟨1|+(0.18968-0.00239967im)|1⟩⟨0|+0.0373817|1⟩⟨1|\n"
    @test sprint((io, x) -> dirac(io, x, header=true), sparse( psi ⊗ dagger(psi)) ) == "SparseOperator(dim=2x2)\n  basis: Spin(1/2)\nρ = 0.962618|0⟩⟨0|+(0.18968+0.00239967im)|0⟩⟨1|+(0.18968-0.00239967im)|1⟩⟨0|+0.0373817|1⟩⟨1|\n"
    @test sprint((io, x) -> dirac(io, x, header=false), psi) == "|ψ⟩ = (0.65825+0.727547im)|0⟩+(0.131519+0.141719im)|1⟩\n"
    @test sprint((io, x) -> dirac(io, x, header=false), psi ⊗ dagger(psi)) == "ρ = 0.962618|0⟩⟨0|+(0.18968+0.00239967im)|0⟩⟨1|+(0.18968-0.00239967im)|1⟩⟨0|+0.0373817|1⟩⟨1|\n"
    @test sprint((io, x) -> dirac(io, x, header=false), sparse( psi ⊗ dagger(psi)) ) == "ρ = 0.962618|0⟩⟨0|+(0.18968+0.00239967im)|0⟩⟨1|+(0.18968-0.00239967im)|1⟩⟨0|+0.0373817|1⟩⟨1|\n"

end # "QuantumOptics"
