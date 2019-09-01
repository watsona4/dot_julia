using EDFPlus
using Test
# Run tests

@elapsed begin
    @time @test include("readtest.jl")
    @time @test include("writetest.jl")
end
