# License is MIT: LICENSE.md

using ModuleInterfaceTools

using Test

@api use StrLiterals, StrEntities

@testset "LaTeX Entities" begin
    @test f"\<dagger>" == "†"
    #@test f"\<mscrl>" == "𝓁" # \U1f4c1
    @test f"\<c_l>" == "𝓁" # \U1f4c1
    @test f"\<nleqslant>" == "⩽̸" # \u2a7d\u338
end
@testset "Emoji Entities" begin
    @test f"\:sailboat:" == "\u26f5"
    @test f"\:ring:"     == "\U1f48d"
    @test f"\:flag-us:"  == "\U1f1fa\U1f1f8"
end
@testset "Unicode Entities" begin
    @test f"\N{end of text}" == "\x03" # \3
    @test f"\N{TIBETAN LETTER -A}" == "\u0f60"
    @test f"\N{LESS-THAN OR SLANTED EQUAL TO}" == "\u2a7d"
    @test f"\N{REVERSED HAND WITH MIDDLE FINGER EXTENDED}" == "\U1f595"
end
@testset "HTML Entities" begin
    @test f"\&nle;"    == "\u2270"
    @test f"\&Pscr;"   == "\U1d4ab"
    @test f"\&lvnE;"   == "\u2268\ufe00"
end
@testset "Unicode constants" begin
    @test f"\u{3}"     == "\x03"
    @test f"\u{f60}"   == "\u0f60"
    @test f"\u{2a7d}"  == "\u2a7d"
    @test f"\u{1f595}" == "\U0001f595"
end
