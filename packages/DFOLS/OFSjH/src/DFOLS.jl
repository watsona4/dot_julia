module DFOLS
using PyCall, Printf

const dfols = PyNULL()
function __init__()
    copy!(dfols, pyimport("dfols"))
end

# Key objects
struct DFOLSResults{TI, TF}
    x::Array{TF, 1}
    resid::Array{TF, 1}
    f::TF
    jacobian::Union{Nothing, Matrix{TF}} # jacobian is nothing if convergence is immediate
    nf::TI
    nx::TI # differs from nf if sample averaging is used
    nruns::TI # > 1 if multiple restarts
    flag::TI
    msg::String
    EXIT_SUCCESS::TI
    EXIT_MAXFUN_WARNING::TI
    EXIT_SLOW_WARNING::TI
    EXIT_FALSE_SUCCESS_WARNING::TI
    EXIT_INPUT_ERROR::TI
    EXIT_TR_INCREASE_ERROR::TI
    EXIT_LINALG_ERROR::TI
end

# see DFOLS documentation for kwargs
function solve(objfun, x0::Array{TF, 1};
                bounds = nothing,
                npt = nothing,
                rhobeg = nothing,
                rhoend = 1e-8,
                maxfun = nothing,
                nsamples = nothing,
                user_params = nothing, # see https://numericalalgorithmsgroup.github.io/dfols/build/html/advanced.html
                objfun_has_noise = false,
                scaling_within_bounds = false) where {TF <: AbstractFloat}

    # grab solution from Python
    soln = dfols[:solve](objfun, x0,
                        bounds = bounds,
                        npt = npt,
                        rhobeg = rhobeg,
                        rhoend = rhoend,
                        nsamples = nsamples,
                        user_params = user_params,
                        objfun_has_noise = objfun_has_noise,
                        scaling_within_bounds = scaling_within_bounds)

    # convergence check
    soln[:flag] == soln[:EXIT_SUCCESS] || error(soln[:msg])

    # return Julia object
    TI = Int # Int64 on 64-bit systems, Int32 on ...
    DFOLSResults{TI, TF}(soln[:x],
                soln[:resid],
                soln[:f],
                soln[:jacobian],
                soln[:nf],
                soln[:nx],
                soln[:nruns],
                soln[:flag],
                soln[:msg],
                soln[:EXIT_SUCCESS],
                soln[:EXIT_MAXFUN_WARNING],
                soln[:EXIT_SLOW_WARNING],
                soln[:EXIT_FALSE_SUCCESS_WARNING],
                soln[:EXIT_INPUT_ERROR],
                soln[:EXIT_TR_INCREASE_ERROR],
                soln[:EXIT_LINALG_ERROR])
end

# Helper functions
converged(d::DFOLSResults) = (d.flag == d.EXIT_SUCCESS)
optimizer(d::DFOLSResults) = d.x
optimum(d::DFOLSResults) = d.f
residuals(d::DFOLSResults) = d.resid
jacobian(d::DFOLSResults) = d.jacobian
nf(d::DFOLSResults) = d.nf
nruns(d::DFOLSResults) = d.nruns
nx(d::DFOLSResults) = d.nx
flag(d::DFOLSResults) = d.flag
msg(d::DFOLSResults) = d.msg

# show()
function Base.show(io::IO, d::DFOLSResults)
    @printf io " * Results of Optimization Algorithm\n"
    @printf io " * Solution: [%s]\n" join(optimizer(d), ",")
    @printf io " * f(x) at Optimum: %f\n" optimum(d)
    @printf io " * Convergence: %s\n" converged(d)
    @printf io " * Exit Message: %s\n" msg(d)
    @printf io " * Exit Flag: %s\n" flag(d)
    @printf io " * Function Calls: %d\n" nf(d)
    @printf io " * Solver Runs: %d\n" nruns(d)
    @printf io " * Point Evaluations: %d\n" nx(d)
    return
end


# Exports
export solve, DFOLSResults, # key objects
        converged, optimizer, optimum, residuals, jacobian, nf, nruns, nx, flag, msg

end # module
