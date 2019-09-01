import Base: run


"""
    Action(func, args...; kwargs...)

An `Action` is a structure (a functor in fact) which stores function, arguments and keyword arguments.

An `Action` can be run (in fact it's run internally by a scheduler when a `Job` is triggered.)
"""
struct Action
    func::Function
    args
    kwargs

    Action(func, args...; kwargs...) = new(func, args, kwargs)
end

"""
    run(action::Action)

Run `action`.

This function shouldn't be called directly. It's called by scheduler when a job is triggered.
"""
run(action::Action) = action.func(action.args...; action.kwargs...)
