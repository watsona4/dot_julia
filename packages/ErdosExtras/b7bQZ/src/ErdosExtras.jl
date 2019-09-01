__precompile__()
module ErdosExtras
using Erdos
using JuMP
using GLPKMathProgInterface
import BlossomV # matching

LP_SOLVER = GLPKSolverLP()   #GurobiSolver(OutputFlag=0)
MIP_SOLVER = GLPKSolverMIP()


# export set_lp_solver, set_mip_solver, get_lp_solver, get_mip_solver

# set_lp_solver(solv) = (LP_SOLVER=solv; solv)
# set_mip_solver(solv) = (MIP_SOLVER=solv; solv)
#
# get_lp_solver() = LP_SOLVER
# get_mip_solver() = MIP_SOLVER

include("matching/Matching.jl")

export MatchingResult, minimum_weight_perfect_matching,
       minimum_weight_perfect_bmatching

include("tsp/TSP.jl")

export solve_tsp

end # module
