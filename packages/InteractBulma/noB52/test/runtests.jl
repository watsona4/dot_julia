using InteractBulma, InteractBase, Sass
using Test

const _pkg_root = dirname(dirname(@__FILE__))
const _pkg_assets = joinpath(_pkg_root, "assets")

@testset "ijulia" begin
    @test !InteractBase.isijulia()
end

@testset "maketheme" begin
    variables_file = joinpath(InteractBulma.examplefolder, "flatly", "_variables.scss")
    mytheme = InteractBulma.compile_theme(_pkg_assets, variables = variables_file)
    settheme!(mytheme)
    @test isfile(joinpath(_pkg_assets, "main.min.css"))
    @test isfile(joinpath(_pkg_assets, "main_confined.min.css"))
    libs = InteractBase.libraries(mytheme)
    @test all(isfile, libs)
end
