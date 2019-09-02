# Carries along the `u` which is an allocation to save when no callbacks
function handle_callbacks!(integrator,eval_sol_fcn)
  discrete_callbacks = integrator.opts.callback.discrete_callbacks
  continuous_callbacks = integrator.opts.callback.continuous_callbacks
  atleast_one_callback = false

  continuous_modified = false
  discrete_modified = false
  saved_in_cb = false
  if !(typeof(continuous_callbacks)<:Tuple{})
    time,upcrossing,event_occured,event_idx,idx,counter =
              DiffEqBase.find_first_continuous_callback(integrator,continuous_callbacks...)
    if event_occured
      integrator.event_last_time = idx
      integrator.vector_event_last_time = event_idx
      continuous_modified,saved_in_cb = DiffEqBase.apply_callback!(integrator,continuous_callbacks[idx],time,upcrossing,event_idx)
    else
      integrator.event_last_time = 0
      integrator.vector_event_last_time = 1
    end
  end
  if !(typeof(discrete_callbacks)<:Tuple{})
    discrete_modified,saved_in_cb = DiffEqBase.apply_discrete_callback!(integrator,discrete_callbacks...)
  end
  if !saved_in_cb
    savevalues!(integrator)
  end

  integrator.u_modified = continuous_modified || discrete_modified
end

function DiffEqBase.savevalues!(integrator::ODEInterfaceIntegrator,force_save=false)::Tuple{Bool,Bool}
  saved, savedexactly = false, false
  !integrator.opts.save_on && return saved, savedexactly
  uType = eltype(integrator.sol.u)

  if integrator.opts.save_everystep || force_save
    saved = true
    push!(integrator.sol.t,integrator.t)
    save_value!(integrator.sol.u,copy(integrator.u),uType,integrator.sizeu)
  end

  while !isempty(integrator.opts.saveat) &&
    integrator.tdir*top(integrator.opts.saveat) < integrator.tdir*integrator.t
    saved = true
    curt = pop!(integrator.opts.saveat)
    tmp = integrator(curt)::Vector{Float64}
    push!(integrator.sol.t,curt)
    save_value!(integrator.sol.u,tmp,uType,integrator.sizeu)
  end
  savedexactly = last(integrator.sol.t) == integrator.t
  return saved, savedexactly
end

function DiffEqBase.change_t_via_interpolation!(integrator::ODEInterfaceIntegrator,t)
  integrator.t = t
  tmp = integrator(integrator.t)::Vector{Float64}
  if eltype(integrator.sol.u) <: Vector
      integrator.u .= tmp
  else
      integrator.u .= reshape(tmp,integrator.sizeu)
  end
  nothing
end
DiffEqBase.get_tmp_cache(i::ODEInterfaceIntegrator,args...) = nothing

@inline function Base.getproperty(integrator::ODEInterfaceIntegrator, sym::Symbol)
  if sym == :dt
    return integrator.t-integrator.tprev
  else
    return getfield(integrator, sym)
  end
end

@inline function DiffEqBase.u_modified!(integrator::ODEInterfaceIntegrator,bool::Bool)
  integrator.u_modified = bool
end

function initialize_callbacks!(integrator, initialize_save = true)
  t = integrator.t
  u = integrator.u
  callbacks = integrator.opts.callback
  integrator.u_modified = true

  u_modified = initialize!(callbacks,u,t,integrator)

  # if the user modifies u, we need to fix current values
  if u_modified
    if initialize_save &&
      (any((c)->c.save_positions[2],callbacks.discrete_callbacks) ||
      any((c)->c.save_positions[2],callbacks.continuous_callbacks))
      savevalues!(integrator,true)
    end
  end

  # reset this as it is now handled so the integrators should proceed as normal
  integrator.u_modified = false
end
