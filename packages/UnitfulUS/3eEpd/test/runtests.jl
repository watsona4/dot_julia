using UnitfulUS
using Test

@testset "US string macro" begin
    @test @macroexpand(us"gal") == UnitfulUS.gal_us
    @test @macroexpand(us"1.0") == 1.0
    @test @macroexpand(us"ton/gal") == UnitfulUS.ton_us / UnitfulUS.gal_us
    @test @macroexpand(us"1.0gal") == 1.0 * UnitfulUS.gal_us
    @test @macroexpand(us"gal^-1") == UnitfulUS.gal_us ^ -1

    @test_throws LoadError @macroexpand(us"ton gal")

    # Disallowed functions
    @test_throws LoadError @macroexpand(us"abs(2)")

    # Units not found
    @test_throws LoadError @macroexpand(us"kg")

    # test ustrcheck(x) fallback to catch non-units / quantities
    @test_throws LoadError @macroexpand(us"ustrcheck")
end
