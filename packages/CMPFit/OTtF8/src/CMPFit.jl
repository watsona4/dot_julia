__precompile__(false)

module CMPFit

using Printf
using Pkg

if isfile(joinpath(dirname(@__FILE__),"..","deps","deps.jl"))
    include("../deps/deps.jl")
else
    error("CMPFit not properly installed. Please run Pkg.build(\"CMPFit\")")
end


# Exported symbols
export cmpfit


######################################################################
# Private definitions
######################################################################

#---------------------------------------------------------------------
"Parameter info strutcture"
mutable struct Parinfo
    fixed::Cint                # 1 = fixed; 0 = free
    limited::NTuple{2, Cint}   # 1 = low/upper limit; 0 = no limit
    limits::NTuple{2, Cdouble} # lower/upper limit boundary value
    char::Ptr{Cchar}           # Name of parameter, or 0 for none
    step::Cdouble              # Step size for finite difference
    relstep::Cdouble           # Relative step size for finite difference
    side::Cint                 #= Sidedness of finite difference derivative
                                  0 - one-sided derivative computed automatically
                                  1 - one-sided derivative (f(x+h) - f(x)  )/h
                                 -1 - one-sided derivative (f(x)   - f(x-h))/h
                                  2 - two-sided derivative (f(x+h) - f(x-h))/(2*h)
                                  3 - user-computed analytical derivatives
                               =#
    deriv_debug::Cint          #= Derivative debug mode: 1 = Yes; 0 = No;
                                  If yes, compute both analytical and numerical
                                  derivatives and print them to the console for
                                  comparison.

                                  NOTE: when debugging, do *not* set side = 3,
                                  but rather to the kind of numerical derivative
                                  you want to compare the user-analytical one to
                                  (0, 1, -1, or 2).
                               =#

    deriv_reltol::Cdouble      # Relative tolerance for derivative debug printout
    deriv_abstol::Cdouble      # Absolute tolerance for derivative debug printout
    
    "Create an empty `Parinfo` structure."
    Parinfo() = new(0, (0, 0), (0, 0), 0, 0, 0, 0, 0, 0, 0)
end


#---------------------------------------------------------------------
"Create a `Vector{Parinfo}` of empty `Parinfo` structures, whose length is given by `npar`."
function Parinfo(npar::Int)
    return [Parinfo() for i in 1:npar]
end


#---------------------------------------------------------------------
#Define sibling structure with toggled mutability
struct imm_Parinfo
    fixed::Cint
    limited::NTuple{2, Cint}
    limits::NTuple{2, Cdouble}
    char::Ptr{Cchar}
    step::Cdouble
    relstep::Cdouble
    side::Cint
    deriv_debug::Cint
    deriv_reltol::Cdouble
    deriv_abstol::Cdouble
end

function imm_Parinfo(p::Parinfo)
    imm_Parinfo(ntuple((i->begin
                        getfield(p, i)
                        end), nfields(p))...)
end


#---------------------------------------------------------------------
"CMPFit config structure"
mutable struct Config
    ftol::Cdouble        # Relative chi-square convergence criterium Default: 1e-10
    xtol::Cdouble        # Relative parameter convergence criterium  Default: 1e-10
    gtol::Cdouble        # Orthogonality convergence criterium       Default: 1e-10
    epsfcn::Cdouble      # Finite derivative step size               Default: eps()
    stepfactor::Cdouble  # Initial step bound                        Default: 100.0
    covtol::Cdouble      # Range tolerance for covariance calculation Default: 1e-14
    maxiter::Cint        # Maximum number of iterations.  If maxiter == MP_NO_ITER,
                         # then basic error checking is done, and parameter
                         # errors/covariances are estimated based on input
                         # parameter values, but no fitting iterations are done.
                         # Default: 200

    maxfev::Cint;        # Maximum number of function evaluations, or 0 for no limit
                         # Default: 0 (no limit)
    nprint::Cint;        # Default: 1
    douserscale::Cint    # Scale variables by user values?
                         # 1 = yes, user scale values in diag;
                         # 0 = no, variables scaled internally (Default)
    nofinitecheck::Cint  # Disable check for infinite quantities from user?
                         # 0 = do not perform check (Default)
                         # 1 = perform check
    iterproc::Cint       # Placeholder pointer - must set to 0

    Config() = new(1e-10, 1e-10, 1e-10, eps(), 100, 1e-14, 200, 0, 1, 0, 0, 0)
end


#---------------------------------------------------------------------
"CMPFit return structure (C side)."
mutable struct Result_C
    bestnorm::Cdouble           # Final chi^2
    orignorm::Cdouble           # Starting value of chi^2
    niter::Cint                 # Number of iterations
    nfev::Cint                  # Number of function evaluations
    status::Cint                # Fitting status code

    npar::Cint                  # Total number of parameters
    nfree::Cint                 # Number of free parameters
    npegged::Cint               # Number of pegged parameters
    nfunc::Cint                 # Number of residuals (= num. of data points)

    resid::Ptr{Cdouble}         # Final residuals nfunc-vector, or 0 if not desired
    perror::Ptr{Cdouble}        # Final parameter uncertainties (1-sigma) npar-vector, or 0 if not desired
    covar::Ptr{Cdouble}         # Final parameter covariance matrix npar x npar array, or 0 if not desired
    version::NTuple{20, Cchar}  # `mpfit` version string

    "Create an empty `Result_C` structure."
    Result_C() = new(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NTuple{20, Cchar}("\0"^20))
end


#---------------------------------------------------------------------
"CMPFit return structure (Julia side)."
mutable struct Result
    bestnorm::Float64           # Final chi^2
    orignorm::Float64           # Starting value of chi^2
    niter::Int64                # Number of iterations
    nfev::Int64                 # Number of function evaluations
    status::Int64               # Fitting status code

    npar::Int64                 # Total number of parameters
    nfree::Int64                # Number of free parameters
    npegged::Int64              # Number of pegged parameters
    nfunc::Int64                # Number of residuals (= num. of data points)

    perror::Vector{Float64}     # Final parameter uncertainties (1-sigma)
    covar::Matrix{Float64}      # Final parameter covariance matrix
    version::String             # CMPFit version string
    param::Vector{Float64}      # Array of best fit parameters
    dof::Int                    # Degrees of freedom
    elapsed::Float64            # Elapsed time [s]
end


#---------------------------------------------------------------------
# Add Base.show method to show CMPFit results
function Base.show(stream::IO, res::Result)
    @printf "  CMPFit ver. = %s\n"  res.version
    @printf "      STATUS = %d\n"   res.status
    @printf "  CHI-SQUARE = %f    (%d DOF)\n"  res.bestnorm  res.dof
    @printf "        NPAR = %d\n"   res.npar
    @printf "       NFREE = %d\n"   res.nfree
    @printf "     NPEGGED = %d\n"   res.npegged
    @printf "       NITER = %d\n"   res.niter
    @printf "        NFEV = %d\n"   res.nfev
    @printf "Elapsed time = %f s\n" res.elapsed

    @printf "\n"
    for i in 1:res.npar
        @printf "  P[%d] = %f +/- %f\n"  i  res.param[i]  res.perror[i]
    end
end


#---------------------------------------------------------------------
mutable struct Wrap_A_Function
    funct::Function
end


#---------------------------------------------------------------------
# This function can not be nested into mpfit since this would lead to the error:
#   ERROR: closures are not yet c-callable
#
"Function called from C to calculate the residuals"
function julia_eval_resid(ndata::Cint, npar::Cint, _param::Ptr{Cdouble}, _resid::Ptr{Cdouble}, dummy::Ptr{Nothing}, _funct::Ptr{Wrap_A_Function})
    wrap  = unsafe_load(_funct)
    param = unsafe_wrap(Vector{Float64}, _param, npar)
    resid = unsafe_wrap(Vector{Float64}, _resid, ndata)

    # Compute residuals
    try
        jresid = wrap.funct(param)
        resid .= reshape(jresid, length(jresid))
    catch err
        println("An error occurred during model evaluation: ")
        println(err)
        return Cint(-1)::Cint
    end

    return Cint(0)::Cint
end

#C-compatible address of the Julia `julia_eval_resid` function.
const c_eval_resid = @cfunction(julia_eval_resid, Cint, (Cint, Cint, Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Nothing}, Ptr{Wrap_A_Function}))


######################################################################
# Public functions
######################################################################


#---------------------------------------------------------------------
"Main CMPFit function"
function cmpfit(funct::Function,
                _param::Vector{Float64};
                parinfo=nothing, config=nothing)

    # Compute elapsed time
    elapsedtime = Base.time_ns()

    # Use a local copy
    param = deepcopy(_param)

    # Check user function by evaluating it
    model = funct(param)

    res_C = Result_C()
    res_C.perror = Libc.malloc(length(param)   * sizeof(Cdouble) )
    res_C.covar  = Libc.malloc(length(param)^2 * sizeof(Cdouble) )

    if parinfo == nothing
        parinfo = Parinfo(length(param))
    end
    if length(parinfo) != length(param)
        error("Lengths of `param` and `parinfo` arrays are different")
    end
    imm_parinfo = map(imm_Parinfo, parinfo)

    if config == nothing
        config = Config()
    end

    wrap = Wrap_A_Function(funct)
    
    status = -999
    try
        status = ccall((:mpfit, libmpfit), Cint,
                       (Ptr{Nothing}, Cint         , Cint,          Ptr{Cdouble}, Ptr{imm_Parinfo}, Ptr{Config}, Ptr{Wrap_A_Function}, Ref{Result_C}),
                       c_eval_resid , length(model), length(param), param       , imm_parinfo     , Ref(config), Ref(wrap)           , res_C)
    catch err
        print_with_color(:red, bold=true, "An error occurred during `mpfit` call:\n")
        println(err)
        println("")
    end

    perror = Vector{Float64}();
    covar  = Array{Float64, 2}(undef, 0, 0)
    
    if status > 0
        covar = Vector{Float64}()
        for i in 1:length(param)  ; push!(perror, unsafe_load(res_C.perror, i)); end
        for i in 1:length(param)^2; push!(covar , unsafe_load(res_C.covar , i)); end
        covar  = reshape(covar, length(param), length(param))
    else
        warn("mpfit returned status = " * string(status) * " < 0.")
    end

    version = findall(x -> x != 0, collect(res_C.version))
    if length(version) == 0
        version = ""
    else
        version = join(Char.(res_C.version[version]))
    end

    result = Result(res_C.bestnorm,
                    res_C.orignorm,
                    res_C.niter,
                    res_C.nfev,
                    res_C.status,
                    res_C.npar,
                    res_C.nfree,
                    res_C.npegged,
                    res_C.nfunc,
                    perror,
                    covar,
                    version,
                    param,
                    res_C.nfunc - res_C.nfree,
                    0.)

    Libc.free(res_C.perror)
    Libc.free(res_C.covar )

    elapsedtime = Base.time_ns() - elapsedtime
    result.elapsed = convert(Float64, elapsedtime / 1e9)

    return result
end


#---------------------------------------------------------------------
function cmpfit(independentData::AbstractArray, 
                observedData::AbstractArray, 
                uncertainties::AbstractArray,
                funct::Function,
                guessParam::Vector{Float64}; 
                parinfo=nothing, config=nothing)
    function cmpfit_callback(param::Vector{Float64})
        model = funct(independentData, param)
        ret = (observedData - model) ./ uncertainties
        return ret
    end
    cmpfit(cmpfit_callback, guessParam, parinfo=parinfo, config=config)
end

end # module
