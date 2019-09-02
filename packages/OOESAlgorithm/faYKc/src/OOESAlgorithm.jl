__precompile__()
module OOESAlgorithm

using Distributed, MathOptInterface, JuMP, MathProgBase, GLPK, GLPKMathProgInterface, Pkg, SparseArrays

println("******************************************************************")
println("*****                     OOESAlgorithm                      *****")
println("*****           A comprehensive Julia package for            *****")
println("***** Bi-Objective Mixed Integer Linear Programming Problems *****")
println("***** To report any bug, email us at:                        *****")
println("*****    amsierra@mail.usf.edu   &  hcharkhgard@usf.edu      *****")
println("*****                                                        *****")
println("***** To Support us, please cite:                            *****")
println("***** Sierra-Altamiranda, A., Charkhgard, H., 2018. A new    *****")
println("***** exact algorithm to optimize a linear function over     *****")
println("***** the set of efficient solutions for bi-objective mixed  *****")
println("***** integer linear programming. INFORMS Journal on         *****")
println("***** Computing To appear.                                   *****")
println("*****                                                        *****")
println("***** Sierra-Altamiranda, A. and Charkhgard, H., 2018.       *****")
println("***** OOESAlgorithm.jl: A julia package for optimizing a     *****")
println("***** linear function over the set of efficient solutions    *****")
println("***** for bi-objective mixed integer linear programming.     *****")
println("******************************************************************")

println("Using GLPKSolverMIP as default solver")
if ("Gurobi" in keys(Pkg.installed()))
	using Gurobi
	println("For using GurobiSolver, add mipsolver=2")
end
if ("CPLEX" in keys(Pkg.installed()))
	using CPLEX
	println("For using CplexSolver, add mipsolver=3")
end
if ("SCIP" in keys(Pkg.installed()))
	using SCIP
	println("For using SCIPSolver, add mipsolver=4")
end
if ("Xpress" in keys(Pkg.installed()))
	using Xpress
	println("For using XpressSolver, add mipsolver=5")
end
include("OOES_Algorithm.jl")

export OOES

end
