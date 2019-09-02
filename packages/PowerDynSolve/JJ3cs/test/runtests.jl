using Test
using Crayons

testlist = [
    ("intergration.jl", "Integration Tests"),
    ("gridsolutions.jl", "Grid Solutions Tests"),
    ("plotrecipes.jl", "Plot Recipes Tests"),
]

@testset "All Tests" begin
    @testset "$desc" for (file, desc) in testlist
        t = @elapsed include(file)
        println(Crayon(foreground = :green, bold = true), "$desc:", Crayon(reset = true), " $t s")
    end
end

# @testset "All Tests" begin
#     @testset "$desc" for (file, desc) in testlist
#         t = @elapsed include(file)
#         println(Crayon(foreground = :green, bold = true), "$desc:", Crayon(reset = true), " $t s")
#     end
# end
