using Pkg
pkg"build PyPlot"

using Test, PlotReferenceImages


ENV["MPLBACKEND"]="agg" # no pyplot GUI


@testset "PlotReferenceImages" begin
    @test generate_reference_image(:gr, 1, false) == nothing
    @test generate_reference_image(:pyplot, 1, false) == nothing
    @test generate_reference_image(:plotlyjs, 1, false) == nothing
    @test generate_reference_image(:pgfplots, 1, false) == nothing
    @test generate_doc_image("lines_1", false) == nothing
    @test generate_doc_image("pipeline_1", false) == nothing
    @test generate_doc_image("backends_1", false) == nothing
end
