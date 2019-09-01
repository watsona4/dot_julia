using Test
using LinearAlgebra
import Granular

function run_test(filename::String)
    printstyled("Info: #### $filename ####\n", color=:green)
    include(filename)
end

run_test("compressive_failure.jl")
run_test("cohesion.jl")
run_test("grain.jl")
run_test("vtk.jl")
run_test("collision-2floes-normal.jl")
run_test("collision-5floes-normal.jl")
run_test("collision-2floes-oblique.jl")
run_test("grid.jl")
run_test("contact-search-and-geometry.jl")
run_test("grid-boundaries.jl")
run_test("ocean.jl")
run_test("atmosphere.jl")
run_test("wall.jl")
run_test("packing.jl")
run_test("util.jl")
run_test("temporal.jl")
if Granular.hasNetCDF
    run_test("netcdf.jl")
end
run_test("jld2.jl")
