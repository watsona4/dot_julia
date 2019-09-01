# Inspired from JuMP/test/solvers

function try_import(name::Symbol)
    try
        @eval import $name
        return true
    catch e
        return false
    end
end

# Load available solvers
grb = try_import(:Gurobi)
cpx = try_import(:CPLEX)
xpr = try_import(:Xpress)
mos = false && try_import(:Mosek)
cbc = try_import(:Cbc)
if cbc; import Clp; end
import GLPKMathProgInterface
glp = true
ipt = try_import(:Ipopt)
eco = try_import(:ECOS)

# Create LP solver list
lp_solvers = Any[]
grb && push!(lp_solvers, Gurobi.GurobiSolver(OutputFlag=0))
cpx && push!(lp_solvers, CPLEX.CplexSolver(CPX_PARAM_SCRIND=0))
xpr && push!(lp_solvers, Xpress.XpressSolver(OUTPUTLOG=0))
mos && push!(lp_solvers, Mosek.MosekSolver(LOG=0))
cbc && push!(lp_solvers, Clp.ClpSolver())
glp && push!(lp_solvers, GLPKMathProgInterface.GLPKSolverLP())
ipt && push!(lp_solvers, Ipopt.IpoptSolver(print_level=0))
eco && push!(lp_solvers, ECOS.ECOSSolver(verbose=false))
