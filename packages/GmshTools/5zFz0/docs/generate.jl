using Literate

EXAMPLEDIR = joinpath(@__DIR__, "src", "examples")
GENERATEDDIR = joinpath(@__DIR__, "src", "examples", "generated")

for example in filter!(x -> endswith(x, ".jl"), readdir(EXAMPLEDIR))
    input = abspath(joinpath(EXAMPLEDIR, example))
    Literate.markdown(input, GENERATEDDIR)
end
