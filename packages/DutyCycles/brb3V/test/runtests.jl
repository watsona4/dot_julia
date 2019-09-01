using DutyCycles
using DutyCycles: check # Let's wrap every DutyCycle (in these unit
                        # tests) in a call to check. This asserts that
                        # the internal representation of the DutyCycle
                        # is valid.
include("all.jl")

# abuse test system to build docs
#@testset "doc generation" begin
#    dir = pwd()
#    cd(joinpath(dirname(pathof(DutyCycles)), "../docs"))
#    # ensure the src dir can be accessed
#    push!(LOAD_PATH, joinpath(dirname(pathof(DutyCycles))))
#    # To Do: test that no warnings are generated
#    include("../docs/make.jl")
#    cd(dir)
#end
