function build_ode(name,ics,pars,vars,tdomain)
  dsargs = ds[:args]()
  set_name(dsargs,name)
  set_ics(dsargs,ics)
  set_pars(dsargs,pars)
  set_vars(dsargs,vars)
  set_tdomain(dsargs,tdomain)
  dsargs
end

function build_ode(f::DiffEqBase.AbstractParameterizedFunction,u0,tspan,p)
  name = string(typeof(f))
  pars = Dict{String,Any}(); vars = Dict{String,Any}(); ics = Dict{String,Any}()
  for i in 1:length(f.params)
    pars[string(f.params[i])] = p[i]
  end
  for i in 1:length(f.syms)
    vars[string(f.syms[i])] = string(f.funcs[i])
    ics[string(f.syms[i])] = u0[i]
  end
  build_ode(name,ics,pars,vars,tspan)
end

function solve_ode(dsargs,alg=:Vode_ODEsystem,name="Default Name")
  DS = ds[:Generator][alg](dsargs)
  traj = DS[:compute](name)
  d = interpert_traj(traj)

  #=
  # Interpolations
  t = 5.4
  traj(t)[:coordarray]
  =#
end

function interpert_traj(traj)
  d = Dict{Symbol,Vector{Float64}}()
  d[Symbol(traj[:indepvarname])] = first(first(values(traj[:underlyingMesh]())))
  depvars = PyDict(traj[:sample]())
  for k in keys(depvars)
    d[Symbol(k)] = depvars[k]
  end
  d
end
