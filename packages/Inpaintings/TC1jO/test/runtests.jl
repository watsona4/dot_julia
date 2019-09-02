using Inpaintings, Test

my_tests = [
    "test_peaks.jl"
]

println("Running tests:")

@testset "Inpaintings.jl" begin
    @testset "$my_test" for my_test in my_tests
        println("  * $(my_test) *")
        include(my_test)
        println("\n\n")
    end
end

println("Tests finished")