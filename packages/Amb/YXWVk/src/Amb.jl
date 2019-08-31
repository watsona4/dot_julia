module Amb

export @amb, require, ambrun, @ambrun, ambiter

using Cassette

function _amb end

# more warning
macro amb(expr...)
    :(_amb($(map(x-> esc(:(()-> $x)), expr)...)))
end

Cassette.@context AmbCtx

struct RunState
    path::Vector{Int}
    cursor::Base.RefValue{Int}
end

struct Escape end

function ambrun(f, ctx = Cassette.disablehooks(AmbCtx(metadata=RunState([], Ref(0)))))
    state = ctx.metadata
    @label beginning
    try
        Cassette.overdub(ctx, f)
    catch err
        if err isa Escape
            # no more branches down here, also we've exhausted this amb
            # back up
            resize!(state.path, length(state.path)-1)
            if isempty(state.path)
                return nothing
            end
            state.path[end] += 1
            state.cursor[] = 0
            # repeat
            @goto beginning
        else
            rethrow(err)
        end
    end
end

macro ambrun(expr)
    :(ambrun(()->$(esc(expr))))
end

function ambiter(f)
    Channel() do c
        ambrun() do
            put!(c, f())
            @amb
        end
    end
end

function Cassette.overdub(ctx::AmbCtx, ::typeof(_amb), args...)
    state = ctx.metadata
    i = (state.cursor[] += 1)
    if i > length(state.path)
        push!(state.path, 1) # discovered a new `amb`
        @assert i == length(state.path)
    end

    if state.path[i] > length(args)
        throw(Escape())
    end

    Cassette.overdub(ctx, args[state.path[i]])
end

require(cond) = cond ? nothing : @amb()

end # module
