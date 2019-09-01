#=
NonlinearFittingTests:
- Julia version: 1.0
- Author: qz
- Date: Jan 29, 2019
=#
module NonlinearFittingTests

using Test

using EquationsOfState

@testset "Test getting fitting parameters" begin
    @test get_fitting_parameters(Birch(1, 2, 3.0)) == [1.0, 2.0, 3.0]
    @test get_fitting_parameters(Murnaghan(1, 2, 3.0)) == [1.0, 2.0, 3.0]
    @test get_fitting_parameters(BirchMurnaghan2nd(1, 2.0)) == [1.0, 2.0]
    @test get_fitting_parameters(BirchMurnaghan3rd(1, 2, 3.0)) == [1.0, 2.0, 3.0]
    @test get_fitting_parameters(BirchMurnaghan4th(1, 2.0, 3, 4)) == [1.0, 2.0, 3.0, 4.0]
    @test get_fitting_parameters(Vinet(1, 2, 3.0)) == [1.0, 2.0, 3.0]
    @test get_fitting_parameters(PoirierTarantola2nd(1, 2.0)) == [1.0, 2.0]
    @test get_fitting_parameters(PoirierTarantola3rd(1, 2, 3.0)) == [1.0, 2.0, 3.0]
    @test get_fitting_parameters(PoirierTarantola4th(1, 2, 3, 4)) == [1, 2, 3, 4]
    @test get_fitting_parameters(Holzapfel(1, 2, 3.0, 4.0)) == [1.0, 2.0, 3.0]
    @test get_fitting_parameters(AntonSchmidt(1, 2, 3.0)) == [1.0, 2.0, 3.0]
    @test get_fitting_parameters(BreenanStacey(1, 2, 3.0)) == [1.0, 2.0, 3.0]
end

@testset "Test fitting energy" begin
    fit_energy(Birch(1, 2, 3.0), [1, 2, 3, 4, 5], [5, 6, 9, 8, 7])
    fit_energy(Birch(1, 2, 3), [1, 2, 3, 4, 5.0], [5, 6, 9, 8, 7])
    fit_energy(Birch(1, 2, 3.0), [1, 2, 3, 4, 5], [5, 6, 9, 8, 7.0])
    fit_energy(Birch(1, 2, 3), [1, 2, 3, 4, 5], [5, 6, 9, 8, 7])
end

@testset "Test fitting pressure" begin
    fit_pressure(Birch(1, 2, 3.0), [1, 2, 3, 4, 5], [5, 6, 9, 8, 7])
    fit_pressure(Birch(1, 2, 3), [1, 2, 3, 4, 5.0], [5, 6, 9, 8, 7])
    fit_pressure(Birch(1, 2, 3.0), [1, 2, 3, 4, 5], [5, 6, 9, 8, 7.0])
    fit_pressure(Birch(1, 2, 3), [1, 2, 3, 4, 5], [5, 6, 9, 8, 7])
end

@testset "Test fitting bulk modulus" begin
    fit_bulk_modulus(BirchMurnaghan3rd(1, 2, 3.0), [1, 2, 3, 4, 5], [5, 6, 9, 8, 7])
    fit_bulk_modulus(BirchMurnaghan3rd(1, 2, 3), [1, 2, 3, 4, 5.0], [5, 6, 9, 8, 7])
    fit_bulk_modulus(BirchMurnaghan3rd(1, 2, 3.0), [1, 2, 3, 4, 5], [5, 6, 9, 8, 7.0])
    fit_bulk_modulus(BirchMurnaghan3rd(1, 2, 3), [1, 2, 3, 4, 5], [5, 6, 9, 8, 7])
end

end