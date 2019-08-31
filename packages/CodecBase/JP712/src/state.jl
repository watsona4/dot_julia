# State
# =====

mutable struct State
    state::Symbol
    State() = new(:init)
end

function start!(state::State)
    state.state = :running
end

function finish!(state::State)
    state.state = :finished
end

function is_running(state::State)
    return state.state == :running
end
