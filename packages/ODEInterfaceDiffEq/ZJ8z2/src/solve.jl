function DiffEqBase.__solve(
    prob::DiffEqBase.AbstractODEProblem{uType,tuptType,isinplace},
    alg::AlgType,
    timeseries=[],ts=[],ks=[];
    saveat = Float64[],
    verbose=true,save_everystep = isempty(saveat),
    save_on = true,
    save_start = save_everystep || isempty(saveat) || typeof(saveat) <: Number ? true : prob.tspan[1] in saveat,
    timeseries_errors=true,dense_errors=false,
    callback=nothing, alias_u0=false, kwargs...) where
    {uType,tuptType,isinplace,AlgType<:ODEInterfaceAlgorithm}

    tType = eltype(tuptType)

    isstiff = alg isa ODEInterfaceImplicitAlgorithm
    if verbose
        warned = !isempty(kwargs) && check_keywords(alg, kwargs, warnlist)
        if !(typeof(prob.f) <: DiffEqBase.AbstractParameterizedFunction) && isstiff
            if DiffEqBase.has_tgrad(prob.f)
                @warn("Explicit t-gradient given to this stiff solver is ignored.")
                warned = true
            end
        end
        warned && warn_compat()
    end

    callbacks_internal = CallbackSet(callback,prob.callback)

    max_len_cb = DiffEqBase.max_vector_callback_length(callbacks_internal)
    if max_len_cb isa VectorContinuousCallback
      callback_cache = DiffEqBase.CallbackCache(max_len_cb.len,uBottomEltype,uBottomEltype)
    else
      callback_cache = nothing
    end

    tspan = prob.tspan

    o = KW(kwargs)

    u0 = prob.u0

    if typeof(u0) <: Number
        u = [u0]
    else
        if alias_u0
            u = u0
        else
            u = deepcopy(u0)
        end
    end

    tdir = sign(tspan[2]-tspan[1])

    saveat_internal =
      saveat_disc_handling(saveat,tdir,tspan,tType)

    sizeu = size(u)

    o[:RHS_CALLMODE] = ODEInterface.RHS_CALL_INSITU

    if save_everystep
        _timeseries = Vector{uType}(undef,0)
        ts = Vector{tType}(undef,0)
    else
        _timeseries = [copy(u0)]
        ts = [tspan[1]]
    end

    uprev = similar(u)

    sol = DiffEqBase.build_solution(prob,  alg, ts, _timeseries,
                         timeseries_errors = timeseries_errors,
                         calculate_error = false,
                         destats = DiffEqBase.DEStats(0),
                         retcode = :Default)

    opts = DEOptions(saveat_internal,save_on,save_everystep,callbacks_internal)
    integrator = ODEInterfaceIntegrator(u,uprev,tspan[1],tspan[1],prob.p,opts,
                                        false,tdir,sizeu,sol,
                                        (t)->[t],0,1,callback_cache,alg,0.)
    initialize_callbacks!(integrator)

    if !isinplace && typeof(u)<:AbstractArray
        f! = (t,u,du) -> (du[:] = vec(prob.f(reshape(u,sizeu),integrator.p,t)); nothing)
    elseif !(typeof(u)<:Vector{Float64})
        f! = (t,u,du) -> (prob.f(reshape(du,sizeu),reshape(u,sizeu),integrator.p,t);
                          du=vec(du); nothing)
    else
        f! = (t,u,du) -> prob.f(du,u,integrator.p,t)
    end

    outputfcn = OutputFunction(integrator)
    o[:OUTPUTFCN] = outputfcn
    if !(typeof(callbacks_internal.continuous_callbacks)<:Tuple{}) || !isempty(saveat)
        if typeof(alg) <: Union{ddeabm,ddebdf}
            @warn("saveat and continuous callbacks ignored for ddeabm and ddebdf")
            o[:OUTPUTMODE] = ODEInterface.OUTPUTFCN_WODENSE
        else
            o[:OUTPUTMODE] = ODEInterface.OUTPUTFCN_DENSE
        end
    else
        o[:OUTPUTMODE] = ODEInterface.OUTPUTFCN_WODENSE
    end

    dict = buildOptions(o,
                        ODEINTERFACE_OPTION_LIST,
                        ODEINTERFACE_ALIASES,
                        ODEINTERFACE_ALIASES_REVERSED)
    if prob.f.mass_matrix != I
        if typeof(prob.f.mass_matrix) <: Matrix && isstiff
            dict[:MASSMATRIX] = prob.f.mass_matrix
        elseif !isstiff
            error("This solver does not support mass matrices")
        else
            error("This solver must use full or banded mass matrices.")
        end
    end
    if DiffEqBase.has_jac(prob.f)
        dict[:JACOBIMATRIX] = (t,u,J) -> prob.f.jac(J,u,prob.p,t)
    end

    if isstiff && alg.jac_lower !== nothing
        dict[:JACOBIBANDSSTRUCT] = (alg.jac_lower,alg.jac_upper)
    end

    # Convert to the strings
    opts = ODEInterface.OptionsODE([Pair(ODEINTERFACE_STRINGS[k],v) for (k,v) in dict]...)


    if typeof(alg) <: dopri5
        tend, uend, retcode, stats =
            ODEInterface.dopri5(f!, tspan[1], tspan[2], vec(integrator.u), opts)
    elseif typeof(alg) <: dop853
        tend, uend, retcode, stats =
            ODEInterface.dop853(f!, tspan[1], tspan[2], vec(integrator.u), opts)
    elseif typeof(alg) <: odex
        tend, uend, retcode, stats =
            ODEInterface.odex(f!, tspan[1], tspan[2], vec(integrator.u), opts)
    elseif typeof(alg) <: seulex
        tend, uend, retcode, stats =
            ODEInterface.seulex(f!, tspan[1], tspan[2], vec(integrator.u), opts)
    elseif typeof(alg) <: radau
        tend, uend, retcode, stats =
            ODEInterface.radau(f!, tspan[1], tspan[2], vec(integrator.u), opts)
    elseif typeof(alg) <: radau5
        tend, uend, retcode, stats =
            ODEInterface.radau5(f!, tspan[1], tspan[2], vec(integrator.u), opts)
    elseif typeof(alg) <: rodas
        tend, uend, retcode, stats =
            ODEInterface.rodas(f!, tspan[1], tspan[2], vec(integrator.u), opts)
    elseif typeof(alg) <: ddeabm
        tend, uend, retcode, stats =
            ODEInterface.ddeabm(f!, tspan[1], tspan[2], vec(integrator.u), opts)
    elseif typeof(alg) <: ddebdf
        tend, uend, retcode, stats =
            ODEInterface.ddebdf(f!, tspan[1], tspan[2], vec(integrator.u), opts)
    end

    if !save_everystep
        push!(ts,tend)
        save_value!(_timeseries,uend,uType,sizeu)
    end

    if retcode < 0
        if retcode == -1
            verbose && @warn("Input is not consistent.")
            return_retcode = :Failure
        elseif retcode == -2
            verbose && @warn("Interrupted. Larger maxiters is needed.")
            return_retcode = :MaxIters
        elseif retcode == -3
            verbose && @warn("Step size went too small.")
            return_retcode = :DtLessThanMin
        elseif retcode == -4
            verbose && @warn("Interrupted. Problem is probably stiff.")
            return_retcode = :Unstable
        end
    else
        return_retcode = :Success
    end

    if DiffEqBase.has_analytic(prob.f)
        DiffEqBase.calculate_solution_errors!(integrator.sol;
        timeseries_errors=timeseries_errors,
        dense_errors=dense_errors)
    end

    destats = sol.destats
    destats.nf = stats["no_rhs_calls"]
    if haskey(stats,"no_steps_rejected")
        destats.nreject = stats["no_steps_rejected"]
        destats.naccept = stats["no_steps_accepted"]
    end
    if haskey(stats,"no_jac_calls")
        destats.njacs = stats["no_jac_calls"]
    end
    if haskey(stats,"no_lu_decomp")
        destats.nw = stats["no_lu_decomp"]
    end
    DiffEqBase.solution_new_retcode(sol,return_retcode)
end

function save_value!(_timeseries,u,::Type{T},sizeu) where T<:Number
    push!(_timeseries,first(u))
end

function save_value!(_timeseries,u,::Type{T},sizeu) where T<:Vector
    push!(_timeseries,u)
end

function save_value!(_timeseries,u,::Type{T},sizeu) where T<:Array
    push!(_timeseries,reshape(u,sizeu))
end

function buildOptions(o, optionlist, aliases, aliases_reversed)
    dict1 = Dict{Symbol,Any}([Pair(k,o[k]) for k in (keys(o) ∩ optionlist)])
    dict2 = Dict([Pair(aliases_reversed[k],o[k]) for k in (keys(o) ∩ values(aliases))])
    merge(dict1,dict2)
end

function saveat_disc_handling(saveat,tdir,tspan,tType)

  if typeof(saveat) <: Number
    if (tspan[1]:saveat:tspan[end])[end] == tspan[end]
      saveat_vec = convert(Vector{tType},collect(tType,tspan[1]+saveat:saveat:tspan[end]))
    else
      saveat_vec = convert(Vector{tType},collect(tType,tspan[1]+saveat:saveat:(tspan[end]-saveat)))
    end
  else
    saveat_vec = vec(collect(tType,Iterators.filter(x->tdir*tspan[1]<tdir*x<tdir*tspan[end],saveat)))
  end

  if tdir>0
    saveat_internal = BinaryMinHeap(saveat_vec)
  else
    saveat_internal = BinaryMaxHeap(saveat_vec)
  end

  saveat_internal
end

const ODEINTERFACE_OPTION_LIST =
    Set([:RTOL, :ATOL, :OUTPUTFCN, :OUTPUTMODE, :MAXSTEPS, :STEST, :EPS, :RHO, :SSMINSEL,
         :SSMAXSEL, :SSBETA, :MAXSS, :INITIALSS, :MAXEXCOLUMN, :STEPSIZESEQUENCE,
         :MAXSTABCHECKS, :MAXSTABCHECKLINE, :DENSEOUTPUTWOEE, :INTERPOLDEGRE,
         :SSREDUCTION, :SSSELECTPAR1, :SSSELECTPAR2, :ORDERDECFRAC, :ORDERINCFRAC,
         :OPT_RHO, :OPT_RHO2, :RHSAUTONOMOUS, :M1, :M2, :LAMBDADENSE, :TRANSJTOH,
         :STEPSIZESEQUENCE, :JACRECOMPFACTOR, :MASSMATRIX, :JACOBIMATRIX, :JACOBIBANDSSTRUCT,
         :WORKFORRHS, :WORKFORJAC, :WORKFORDEC, :WORKFORSOL,
         :MAXNEWTONITER, :NEWTONSTARTZERO, :NEWTONSTOPCRIT, :DIMFIND1VAR,
         :MAXSTAGES, :MINSTAGES, :INITSTAGES, :STEPSIZESTRATEGY,
         :FREEZESSLEFT, :FREEZESSRIGHT, :ORDERDECFACTOR,
         :ORDERINCFACTOR, :ORDERDECCSTEPFAC1, :ORDERDECSTEPFAC2, :RHS_CALLMODE
         ])

const ODEINTERFACE_ALIASES =
    Dict{Symbol,Symbol}(:RTOL=>:reltol,
                        :ATOL=>:abstol,
                        :MAXSTEPS=> :maxiters,
                        :MAXSS=>:dtmax,
                        :INITIALSS=>:dt,
                        #:SSMINSEL=>:qmin,
                        :SSBETA=>:beta2,
                        :SSMAXSEL=>:qmax)

const ODEINTERFACE_ALIASES_REVERSED =
    Dict{Symbol,Symbol}([(v,k) for (k,v) in ODEINTERFACE_ALIASES])

const ODEINTERFACE_STRINGS = Dict{Symbol,String}(
  :LOGIO            => "logio",
  :LOGLEVEL         => "loglevel",
  :RHS_CALLMODE     => "RightHandSideCallMode",

  :RTOL             => "RelTol",
  :ATOL             => "AbsTol",
  :MAXSTEPS         => "MaxNumberOfSteps",
  :EPS              => "eps",

  :OUTPUTFCN        => "OutputFcn",
  :OUTPUTMODE       => "OutputFcnMode",

  :STEST            => "StiffTestAfterStep",
  :RHO              => "rho",
  :SSMINSEL         => "StepSizeMinSelection",
  :SSMAXSEL         => "StepSizeMaxSelection",
  :SSBETA           => "StepSizeBeta",
  :MAXSS            => "MaxStep",
  :INITIALSS        => "InitialStep",


  :MAXEXCOLUMN      => "MaxExtrapolationColumn",
  :MAXSTABCHECKS    => "MaxNumberOfStabilityChecks",
  :MAXSTABCHECKLINE => "MaxLineForStabilityCheck",
  :INTERPOLDEGREE   => "DegreeOfInterpolation",
  :ORDERDECFRAC     => "OrderDecreaseFraction",
  :ORDERINCFRAC     => "OrderIncreaseFraction",
  :STEPSIZESEQUENCE => "StepSizeSequence",
  :SSREDUCTION      => "StepSizeReduction",
  :SSSELECTPAR1     => "StepSizeSelectionParam1",
  :SSSELECTPAR2     => "StepSizeSelectionParam2",
  :RHO2             => "rho2",
  :DENSEOUTPUTWOEE  => "DeactivateErrorEstInDenseOutput",

  :TRANSJTOH        => "TransfromJACtoHess",
  :MAXNEWTONITER    => "MaxNewtonIterations",
  :NEWTONSTARTZERO  => "StartNewtonWithZeros",
  :DIMOFIND1VAR     => "DimensionOfIndex1Vars",
  :DIMOFIND2VAR     => "DimensionOfIndex2Vars",
  :DIMOFIND3VAR     => "DimensionOfIndex3Vars",
  :STEPSIZESTRATEGY => "StepSizeStrategy",
  :M1               => "M1",
  :M2               => "M2",
  :JACRECOMPFACTOR  => "RecomputeJACFactor",
  :NEWTONSTOPCRIT   => "NewtonStopCriterion",
  :FREEZESSLEFT     => "FreezeStepSizeLeftBound",
  :FREEZESSRIGHT    => "FreezeStepSizeRightBound",
  :MASSMATRIX       => "MassMatrix",
  :JACOBIMATRIX     => "JacobiMatrix",
  :JACOBIBANDSTRUCT => "JacobiBandStructure",

  :MAXSTAGES        => "MaximalNumberOfStages",
  :MINSTAGES        => "MinimalNumberOfStages",
  :INITSTAGES       => "InitialNumberOfStages",
  :ORDERINCFACTOR   => "OrderIncreaseFactor",
  :ORDERDECFACTOR   => "OrderDecreaseFactor",
  :ORDERDECSTEPFAC1 => "OrderDecreaseStepFactor1",
  :ORDERDECSTEPFAC2 => "OrderDecreaseStepFactor2",

  :RHSAUTONOMOUS    => "AutonomousRHS",
  :LAMBDADENSE      => "LambdaForDenseOutput",
  :WORKFORRHS       => "WorkForRightHandSide",
  :WORKFORJAC       => "WorkForJacobimatrix",
  :WORKFORDEC       => "WorkForLuDecomposition",
  :WORKFORSOL       => "WorkForSubstitution",

  :BVPCLASS         => "BoundaryValueProblemClass",
  :SOLMETHOD        => "SolutionMethod",
  :IVPOPT           => "OptionsForIVPsolver")

struct OutputFunction{T} <: Function
    integrator::T
end

function (f::OutputFunction)(reason::ODEInterface.OUTPUTFCN_CALL_REASON,
      tprev::Float64, t::Float64, u::Vector{Float64},
      eval_sol_fcn, extra_data::Dict)

  if reason == ODEInterface.OUTPUTFCN_CALL_STEP

      integrator = f.integrator

      integrator.uprev .= integrator.u
      if eltype(integrator.sol.u) <: Vector
          integrator.u .= u
      else
          integrator.u .= reshape(u,integrator.sizeu)
      end
      integrator.t = t
      integrator.tprev = tprev
      integrator.eval_sol_fcn = eval_sol_fcn

      handle_callbacks!(integrator,eval_sol_fcn)

      if integrator.u_modified

          if eltype(integrator.sol.u) <: Vector
              u .= integrator.u
          else
              tmp = reshape(u,integrator.sizeu)
              tmp .= integrator.u
          end

          return ODEInterface.OUTPUTFCN_RET_CONTINUE_XCHANGED
      else
          return ODEInterface.OUTPUTFCN_RET_CONTINUE
      end
      # TODO: ODEInterface.OUTPUTFCN_RET_STOP for terminate!

  end

  ODEInterface.OUTPUTFCN_RET_CONTINUE
end
