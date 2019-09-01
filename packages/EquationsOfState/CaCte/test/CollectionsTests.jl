#=
CollectionsTests:
- Julia version: 1.0
- Author: qz
- Date: Jan 29, 2019
=#
module CollectionsTests

using Test

using EquationsOfState

@testset "Test EOS promotion" begin
    @test typeof(Birch(1, 2, 3.0)) == Birch{Float64}
    @test typeof(Murnaghan(1, 2, 3.0)) == Murnaghan{Float64}
    @test typeof(BirchMurnaghan2nd(1, 2.0)) == BirchMurnaghan2nd{Float64}
    @test typeof(BirchMurnaghan3rd(1, 2, 3.0)) == BirchMurnaghan3rd{Float64}
    @test typeof(BirchMurnaghan4th(1, 2.0, 3, 4)) == BirchMurnaghan4th{Float64}
    @test typeof(Vinet(1, 2, 3.0)) == Vinet{Float64}
    @test typeof(PoirierTarantola2nd(1, 2.0)) == PoirierTarantola2nd{Float64}
    @test typeof(PoirierTarantola3rd(1, 2, 3.0)) == PoirierTarantola3rd{Float64}
    @test typeof(PoirierTarantola4th(1, 2, 3, 4)) == PoirierTarantola4th{Int}
    @test typeof(Holzapfel(1, 2, 3.0, 4.0)) == Holzapfel{Float64}
    @test typeof(AntonSchmidt(1, 2, 3.0)) == AntonSchmidt{Float64}
    @test typeof(BreenanStacey(1, 2, 3.0)) == BreenanStacey{Float64}
end

@testset "Test getting parameters" begin
    @test get_parameters(Birch(1, 2, 3.0)) == [1.0, 2.0, 3.0]
    @test get_parameters(Murnaghan(1, 2, 3.0)) == [1.0, 2.0, 3.0]
    @test get_parameters(BirchMurnaghan2nd(1, 2.0)) == [1.0, 2.0]
    @test get_parameters(BirchMurnaghan3rd(1, 2, 3.0)) == [1.0, 2.0, 3.0]
    @test get_parameters(BirchMurnaghan4th(1, 2.0, 3, 4)) == [1.0, 2.0, 3.0, 4.0]
    @test get_parameters(Vinet(1, 2, 3.0)) == [1.0, 2.0, 3.0]
    @test get_parameters(PoirierTarantola2nd(1, 2.0)) == [1.0, 2.0]
    @test get_parameters(PoirierTarantola3rd(1, 2, 3.0)) == [1.0, 2.0, 3.0]
    @test get_parameters(PoirierTarantola4th(1, 2, 3, 4)) == [1, 2, 3, 4]
    @test get_parameters(Holzapfel(1, 2, 3.0, 4.0)) == [1.0, 2.0, 3.0, NonFittingParameter(4.0)]
    @test get_parameters(AntonSchmidt(1, 2, 3.0)) == [1.0, 2.0, 3.0]
    @test get_parameters(BreenanStacey(1, 2, 3.0)) == [1.0, 2.0, 3.0]
end

end