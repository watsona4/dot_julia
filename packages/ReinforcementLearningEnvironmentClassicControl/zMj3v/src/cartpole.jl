struct CartPoleParams{T}
    gravity::T
    masscart::T
    masspole::T
    totalmass::T
    halflength::T
    polemasslength::T
    forcemag::T
    tau::T
    thetathreshold::T
    xthreshold::T
    maxsteps::Int64
end

mutable struct CartPole{T} <: AbstractEnv
    params::CartPoleParams{T}
    actionspace::DiscreteSpace
    observationspace::BoxSpace{T}
    state::Array{T, 1}
    action::Int
    done::Bool
    t::Int64
end

function CartPole(; T = Float64, gravity = T(9.8), masscart = T(1.), 
                  masspole = T(.1), halflength = T(.5), forcemag = T(10.),
                  maxsteps = 200)
    params = CartPoleParams(gravity, masscart, masspole, masscart + masspole,
                            halflength, masspole * halflength, forcemag,
                            T(.02), T(2 * 12 * π /360), T(2.4), maxsteps)
    high = [2 * params.xthreshold, T(1e38),
            2 * params.thetathreshold, T(1e38)]
    cp = CartPole(params, DiscreteSpace(2, 1), BoxSpace(-high, high), 
                  zeros(T, 4), 2, false, 0)
    reset!(cp)
    cp
end

actionspace(env::CartPole) = env.actionspace

function reset!(env::CartPole{T}) where T <: Number
    env.state[:] = T(.1) * rand(T, 4) .- T(.05)
    env.t = 0
    env.action = 2
    env.done = false
    (observation=env.state,)
end

getstate(env::CartPole) = (observation=env.state, isdone=env.done)

function interact!(env::CartPole{T}, a) where T <: Number
    env.action = a
    env.t += 1
    force = a == 2 ? env.params.forcemag : -env.params.forcemag
    x, xdot, theta, thetadot = env.state
    costheta = cos(theta)
    sintheta = sin(theta)
    tmp = (force + env.params.polemasslength * thetadot^2 * sintheta) /
        env.params.totalmass
    thetaacc = (env.params.gravity * sintheta - costheta * tmp) / 
        (env.params.halflength * 
            (4/3 - env.params.masspole * costheta^2/env.params.totalmass))
    xacc = tmp - env.params.polemasslength * thetaacc * costheta / 
        env.params.totalmass
    env.state[1] += env.params.tau * xdot
    env.state[2] += env.params.tau * xacc
    env.state[3] += env.params.tau * thetadot
    env.state[4] += env.params.tau * thetaacc
    env.done = abs(env.state[1]) > env.params.xthreshold ||
               abs(env.state[3]) > env.params.thetathreshold ||
               env.t >= env.params.maxsteps
    (observation=env.state, reward=1., isdone=env.done)
end

function plotendofepisode(x, y, d)
    if d
        setmarkercolorind(7)
        setmarkertype(-1)
        setmarkersize(6)
        polymarker([x], [y])
    end
    return nothing
end
function plotenv(env::CartPole)
    s, a, d = env.state, env.action, env.done
    x, xdot, theta, thetadot = s
    l = 2 * env.params.halflength
    clearws()
    setviewport(0, 1, 0, 1)
    xthreshold = env.params.xthreshold
    setwindow(-xthreshold, xthreshold, -.1, l + .1)
    fillarea([x-.5, x-.5, x+.5, x+.5], [-.05, 0, 0, -.05])
    setlinecolorind(4)
    setlinewidth(3)
    polyline([x, x + l * sin(theta)], [0, l * cos(theta)])
    setlinecolorind(2)
    drawarrow(x + (a == 1) - .5, -.025, x + 1.4 * (a==1) - .7, -.025)
    plotendofepisode(xthreshold - .2, l, d)
    updatews()
end
