module OpenTrick

export opentrick, rawio, blockingtask, unsafe_clear

const tasks_pending=Dict{Condition, Task}()

mutable struct IOWrapper{T <: IO}
    io::T
    cond::Condition
    function IOWrapper(io::T, c) where T
        obj = new{T}(io, c)
        finalizer(obj) do obj
            notify(obj.cond)
        end
    end
end

"""
    opentrick(openfn[, args... [; <keyword arguments>]])

Call `openfn` with `(handlefn, args... ,kwargs ...)` as arguments,
return an `IOWrapper` instance. (NB:`handlefn` is provided by `opentrick`.)

# Arguments
- `openfn::Function` function actually called to obtain a `IO` instance.
  `openfn` must take a `Function(::IO)` instance as its first argument
- `args` optional arguments that will be passed to `openfn`
- `kwargs` optional keyword arguments that will be passed to `openfn`

# Examples
```jldoctest
julia> using OpenTrick

julia> filename = tempname();

julia> io = opentrick(open, filename, "w+");

julia> write(io, "hello world!")
12

julia> seek(io, 0);

julia> readline(io)
"hello world!"

```
"""
function opentrick(open::Function, args...; kwargs...)
    blockreturn() do cond
        open(args ...; kwargs...) do stream
            notifyreturn(cond, stream)
        end
    end
end

"""
    close(io; kwargs...)

Close `io` and unblock the corresponding blocking task.
"""
function Base.close(w::IOWrapper; kwargs...)
    try
        close(rawio(w); kwargs...)
    catch e
        rethrow(e)
    finally
        finalize(w)
        yield()
    end
end

for fname in (
    :read, :read!, :readbytes!, :unsafe_read, :readavailable,
    :readline, :readlines, :eachline, :readchomp, :readuntil, :bytesavailable,
    :write, :unsafe_write, :truncate, :flush,
    :print, :println, :printstyled, :showerror,
    :seek, :seekstart, :seekend, :skip, :skipchars, :position,
    :mark, :unmark, :reset, :ismarked,
    :isreadonly, :iswritable, :isreadable, :isopen, :eof,
    :countlines, :displaysize)
    eval(quote
        @assert isa(Base.$fname, Function)
        Base.$fname(w::IOWrapper, args...; kwargs...) = $fname(rawio(w), args...; kwargs...)
    end)
end

"""
    unsafe_clear()

Unblock all blocking tasks. All `io`s returned by `opentrick` will
be closed as a consequence.
"""
function unsafe_clear()
    for (cond, task) in tasks_pending
        notify(cond, InterruptException(), error=true)
        yield()
    end
end

"""
    rawio(io)

Return the actual `io` instance
"""
rawio(w::IOWrapper) = w.io

"""
    blockingtask(io)

Return the task blocking which prevents the `handlefn` passed to `openfn` from returning
"""
blockingtask(w::IOWrapper) = tasks_pending[w.cond]

"""
call blockreturn in other tasks like in @async block
"""
function notifyreturn(c, x)
    io = IOWrapper(x, c)
    @debug "notifing caller..." io
    notify(c, io, all=false) # caller ought to be waiting for it
    io = nothing # no longer keep reference to
    wait(c)
    @debug "notifyreturn finished"
end

"""
f must accept cond::Condition as its first argument
"""
function blockreturn(f::Function, args...; kwargs...)
    cond = Condition()
    task = @async begin
        try
            @debug "push!" cond current_task() tasks_pending
            push!(tasks_pending, cond => current_task() )
            @debug "calling ..." f args kwargs
            f(cond, args...; kwargs...)
            @debug "call returned" f
        catch e
            @debug "Caught Exception" e
            notify(cond, e, error=true)
        end
        @debug "delete!" current_task() tasks_pending
        delete!(tasks_pending, cond)
        @debug "deleted" tasks_pending

    end
    @debug "waiting" cond task
    return wait(cond)
end

end # module
