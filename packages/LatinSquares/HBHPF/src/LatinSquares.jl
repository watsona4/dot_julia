module LatinSquares
using JuMP
using MathProgBase
using Cbc

SOLVER = CbcSolver


export set_latin_solver

"""
`set_latin_solver(OPT::Module=Cbc)`
"""
function set_latin_solver(OPT::Module=Cbc)
    global SOLVER = OPT
end

set_latin_solver()

include("ortho_latin.jl")
include("latin.jl")
include("latin_print.jl")

# package code goes here

end # module
