module ReinforcementLearningEnvironmentGym
using ReinforcementLearningBase
import ReinforcementLearningBase:interact!, reset!, getstate, plotenv, actionspace
using PyCall
const gym = PyNULL()

function __init__()
    copy!(gym, pyimport_conda("gym", ""))
    pyimport("pybullet_envs")
end

function gymspace2jlspace(s::PyObject)
    spacetype = s[:__class__][:__name__]
    if     spacetype == "Box"           BoxSpace(s[:low], s[:high])
    elseif spacetype == "Discrete"      DiscreteSpace(s[:n], 1)
    elseif spacetype == "MultiBinary"   MultiBinarySpace(s[:n])
    elseif spacetype == "MultiDiscrete" MultiDiscreteSpace(s[:nvec], 1)
    elseif spacetype == "Tuple"         map(gymspace2jlspace, s[:spaces])
    elseif spacetype == "Dict"          Dict(map((k, v) -> (k, gymspace2jlspace(v)), s[:spaces]))
    else error("Don't know how to convert [$(spacetype)]")
    end
end

struct GymEnv{Ta<:AbstractSpace, To<:AbstractSpace} <: AbstractEnv
    pyobj::PyObject
    observationspace::To
    actionspace::Ta
    state::PyObject
end

function GymEnv(name::String)
    pyenv = gym[:make](name)
    obsspace = gymspace2jlspace(pyenv[:observation_space])
    actspace = gymspace2jlspace(pyenv[:action_space])
    state = PyNULL()
    env = GymEnv(pyenv, obsspace, actspace, state)
    reset!(env) # state needs to be set to call defaultbuffer in RL
    env
end

function interact!(env::GymEnv, action)
    pycall!(env.state, env.pyobj[:step], PyVector, action)
    (observation=env.state[1], reward=env.state[2], isdone=env.state[3])
end

function interact!(env::GymEnv{DiscreteSpace}, action::Int)
    pycall!(env.state, env.pyobj[:step], PyVector, action - 1)
    (observation=env.state[1], reward=env.state[2], isdone=env.state[3])
end

function interact!(env::GymEnv{MultiDiscreteSpace}, action::AbstractArray{Int})
    pycall!(env.state, env.pyobj[:step], PyVector, action .- 1)
    (observation=env.state[1], reward=env.state[2], isdone=env.state[3])
end

"Not very useful, kept for compat"
function getstate(env::GymEnv) 
    if pyisinstance(env.state, PyCall.@pyglobalobj :PyTuple_Type)
        (observation=env.state[1], isdone=env.state[3])
    else
        # env has just been reseted
        (observation=Float64.(env.state), isdone=false)
    end
end

reset!(env::GymEnv) = (observation=Float64.(pycall!(env.state, env.pyobj[:reset], PyArray)),)
plotenv(env::GymEnv) = env.pyobj[:render]()
actionspace(env::GymEnv) = env.actionspace

"""
    listallenvs(pattern = r"")

List all registered gym environment names. The optional argument `pattern`
allows to list all environment  that contain the `pattern` in their name.
"""
function listallenvs(pattern = r"")
    envs = sort(py"[spec.id for spec in $gym.envs.registry.all()]")
    if pattern != ""
        envs[findall(x -> occursin(pattern, x), envs)]
    else
        envs
    end
end

export GymEnv, listallenvs
end # module
