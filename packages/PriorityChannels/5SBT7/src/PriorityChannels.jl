module PriorityChannels
export PriorityChannel
using DataStructures
import Base: notify_error, register_taskdone_hook, check_channel_state


const PriorityElement{T,I<:Real} = Tuple{T,I}
const ordering = Base.By(x->x[2])


"""
    PriorityChannel{T}(sz::Int)

Constructs a `PriorityChannel` with an internal buffer that can hold a maximum of `sz` objects
of type `T`, each assigned an real-valued priority (low number = higher priority).
[`put!`](@ref) calls on a full channel block until an object is removed with [`take!`](@ref).

`PriorityChannel(0)` constructs an unbuffered channel. `put!` blocks until a matching `take!` is called.
And vice-versa.

Other constructors:

* `PriorityChannel(Inf)`: equivalent to `PriorityChannel{Any,Int}(typemax(Int))`
* `PriorityChannel(sz)`: equivalent to `PriorityChannel{Any,Int}(sz)`
"""
mutable struct PriorityChannel{T,I} <: AbstractChannel{T}
    cond_take::Condition                 # waiting for data to become available
    cond_put::Condition                  # waiting for a writeable slot
    state::Symbol
    excp::Union{Exception, Nothing}         # exception to be thrown when state != :open

    data::Vector{PriorityElement{T,I}}
    sz_max::Int                          # maximum size of channel

    # Used when sz_max == 0, i.e., an unbuffered channel.
    waiters::Int
    takers::Vector{Task}
    putters::Vector{Task}

    function PriorityChannel{T,I}(sz::Float64) where {T,I<:Real}
        if sz == Inf
            PriorityChannel{T,I}(typemax(Int))
        else
            PriorityChannel{T,I}(convert(Int, sz))
        end
    end
    function PriorityChannel{T,I}(sz::Integer) where {T,I<:Real}
        if sz <= 0
            throw(ArgumentError("Channel size must be a positive integer or Inf"))
        end
        ch = new(Condition(), Condition(), :open, nothing, Vector{PriorityElement{T,I}}(), sz, 0)
        return ch
    end
end

PriorityChannel(sz) = PriorityChannel{Any,Int}(sz)

# special constructors
"""
    PriorityChannel(func::Function; ctype=Any, csize=1, taskref=nothing)

Create a new task from `func`, bind it to a new channel of type
`ctype` and size `csize`, and schedule the task, all in a single call.

`func` must accept the bound channel as its only argument.

If you need a reference to the created task, pass a `Ref{Task}` object via
keyword argument `taskref`.

Return a `PriorityChannel`.

# Examples
```jldoctest
julia> chnl = PriorityChannel(c->foreach(i->put!(c,i), 1:4));

julia> typeof(chnl)
PriorityChannel{Any,Int64}

julia> for i in chnl
           @show i
       end;
i = 1
i = 2
i = 3
i = 4
```

Referencing the created task:

```jldoctest
julia> taskref = Ref{Task}();

julia> chnl = PriorityChannel(c->(@show take!(c)); taskref=taskref);

julia> istaskdone(taskref[])
false

julia> put!(chnl, "Hello");
take!(c) = "Hello"

julia> istaskdone(taskref[])
true
```
"""
function PriorityChannel(func::Function; ctype=Any, csize=1, taskref=nothing)
    csize > 0 || throw(ArgumentError("Channel size must be a positive integer or Inf"))
    chnl = PriorityChannel{ctype,Int}(csize)
    task = Task(() -> func(chnl))
    bind(chnl, task)
    yield(task) # immediately start it

    isa(taskref, Ref{Task}) && (taskref[] = task)
    return chnl
end


closed_exception() = InvalidStateException("Channel is closed.", :closed)

isbuffered(c::PriorityChannel) = true

function Base.check_channel_state(c::PriorityChannel)
    if !isopen(c)
        c.excp !== nothing && throw(c.excp)
        throw(closed_exception())
    end
end

function Base.close(c::PriorityChannel)
    c.state = :closed
    c.excp = closed_exception()
    notify_error(c)
    nothing
end
Base.isopen(c::PriorityChannel) = (c.state == :open)

function Base.bind(c::PriorityChannel, task::Task)
    ref = WeakRef(c)
    register_taskdone_hook(task, tsk->Base.close_chnl_on_taskdone(tsk, ref))
    c
end

"""
    channeled_tasks(n::Int, funcs...; ctypes=fill(Any,n), csizes=fill(0,n))

A convenience method to create `n` channels and bind them to tasks started
from the provided functions in a single call. Each `func` must accept `n` arguments
which are the created channels. PriorityChannel types and sizes may be specified via
keyword arguments `ctypes` and `csizes` respectively. If unspecified, all channels are
of type `Channel{Any}(0)`.

Returns a tuple, `(Array{Channel}, Array{Task})`, of the created channels and tasks.
"""
function channeled_tasks(n::Int, funcs...; ctypes=fill(Any,n), csizes=fill(0,n))
    @assert length(csizes) == n
    @assert length(ctypes) == n

    chnls = map(i -> PriorityChannel{ctypes[i],Int}(csizes[i]), 1:n)
    tasks = Task[ Task(() -> f(chnls...)) for f in funcs ]

    # bind all tasks to all channels and schedule them
    foreach(t -> foreach(c -> bind(c, t), chnls), tasks)
    foreach(schedule, tasks)
    yield() # Allow scheduled tasks to run

    return (chnls, tasks)
end

"""
    put!(c::PriorityChannel, v, p)

Append an item `v` to the channel `c` with priority `p`. Blocks if the channel is full.
"""
function Base.put!(c::PriorityChannel{T,I}, v,i::I = 0) where {T,I<:Real}
    check_channel_state(c)
    while length(c.data) == c.sz_max
        wait(c.cond_put)
    end
    heappush!(c.data, PriorityElement((v,i)), ordering)

    # notify all, since some of the waiters may be on a "fetch" call.
    notify(c.cond_take, nothing, true, false)
    v
end


Base.push!(c::PriorityChannel, v, i=0) = put!(c, v, i)

"""
    fetch(c::PriorityChannel)

Wait for and get the highest priority item from the channel. Does not
remove the item.
"""
function Base.fetch(c::PriorityChannel)
    wait(c)
    c.data[1][1]
end


"""
    take!(c::PriorityChannel)

Remove and return the highest priority value from a [`PriorityChannel`](@ref). Blocks until data is available.
"""
function Base.take!(c::PriorityChannel)
    wait(c)
    v = heappop!(c.data, ordering)[1]
    notify(c.cond_put, nothing, false, false) # notify only one, since only one slot has become available for a put!.
    v
end

Base.popfirst!(c::PriorityChannel) = take!(c)

Base.isready(c::PriorityChannel) = n_avail(c) > 0
n_avail(c::PriorityChannel) = length(c.data)

function Base.wait(c::PriorityChannel)
    while !isready(c)
        check_channel_state(c)
        wait(c.cond_take)
    end
    nothing
end


function Base.notify_error(c::PriorityChannel, err)
    Base.notify_error(c.cond_take, err)
    Base.notify_error(c.cond_put, err)
end
Base.notify_error(c::PriorityChannel) = Base.notify_error(c, c.excp)

Base.eltype(::Type{PriorityChannel{T,I}}) where {T,I} = T

Base.show(io::IO, c::PriorityChannel) = print(io, "$(typeof(c))(sz_max:$(c.sz_max),sz_curr:$(n_avail(c)))")

function Base.iterate(c::PriorityChannel, state=nothing)
    try
        return (take!(c), nothing)
    catch e
        if isa(e, InvalidStateException) && e.state==:closed
            return nothing
        else
            rethrow()
        end
    end
end

Base.IteratorSize(::Type{<:PriorityChannel}) = SizeUnknown()


end # module
