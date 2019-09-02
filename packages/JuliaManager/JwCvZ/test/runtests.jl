module TestJuliaManager

using Test

if lowercase(get(ENV, "CI", "false")) == "true"
    @testset begin include("destructive_tests.jl") end
end

end  # module
