__precompile__()

module DeferredFutures

using AutoHashEquals
using Distributed
using Serialization: AbstractSerializer, serialize_any, serialize_cycle, serialize_type

import Distributed: AbstractRemoteRef
import Serialization: serialize

export @defer, DeferredChannel, DeferredFuture, DeferredRemoteRef, reset!

"""
`DeferredRemoteRef` is the common supertype of `DeferredFuture` and `DeferredChannel` and is
the counterpart of `$AbstractRemoteRef`.
"""
abstract type DeferredRemoteRef <: AbstractRemoteRef end

@auto_hash_equals mutable struct DeferredFuture <: DeferredRemoteRef
    outer::RemoteChannel
end

"""
    DeferredFuture(pid::Integer=myid()) -> DeferredFuture

Create a `DeferredFuture` on process `pid`. The default `pid` is the current process.

Note that the data in the `DeferredFuture` will still be located wherever it was `put!`
from. The `pid` argument controlls where the outermost reference to that data is located.
"""
function DeferredFuture(pid::Integer=myid())
    ref = DeferredFuture(RemoteChannel(pid))
    finalizer(finalize_ref, ref)
    return ref
end

"""
    show(io::IO, ref::DeferredFuture)

Print a simplified string representation of the `DeferredFuture` with its RemoteChannel
parameters.
"""
function Base.show(io::IO, ref::DeferredFuture)
    rc = ref.outer
    print(io, "$(typeof(ref).name.name) at ($(rc.where),$(rc.whence),$(rc.id))")
end

"""
    serialize(s::AbstractSerializer, ref::DeferredFuture)

Serialize a DeferredFuture such that it can de deserialized by `deserialize` in a cluster.
"""
function serialize(s::AbstractSerializer, ref::DeferredFuture)
    serialize_cycle(s, ref) && return

    serialize_type(s, DeferredFuture, true)

    serialize_any(s, ref.outer)
end

@auto_hash_equals mutable struct DeferredChannel <: DeferredRemoteRef
    outer::RemoteChannel
    func::Function  # Channel generating function used for creating the `RemoteChannel`
end

"""
    DeferredChannel(pid::Integer=myid(), num::Integer=1; content::DataType=Any) -> DeferredChannel

Create a `DeferredChannel` with a reference to a remote channel of a specific size and type.
f() is a function that when executed on `pid` must return an implementation of an
`AbstractChannel`.

The default `pid` is the current process.
"""
function DeferredChannel(f::Function, pid::Integer=myid())
    ref = DeferredChannel(RemoteChannel(pid), f)
    finalizer(finalize_ref, ref)
    return ref
end

"""
    DeferredChannel(pid::Integer=myid(), num::Integer=1; content::DataType=Any) -> DeferredChannel

Create a `DeferredChannel`. The default `pid` is the current process. When initialized, the
`DeferredChannel` will reference a `Channel{content}(num)` on process `pid`.

Note that the data in the `DeferredChannel` will still be located wherever the first piece
of data was `put!` from. The `pid` argument controls where the outermost reference to that
data is located.
"""
function DeferredChannel(pid::Integer=myid(), num::Integer=1; content::DataType=Any)
    ref = DeferredChannel(RemoteChannel(pid), ()->Channel{content}(num))
    finalizer(finalize_ref, ref)
    return ref
end

"""
    show(io::IO, ref::DeferredChannel)

Print a simplified string representation of the `DeferredChannel` with its RemoteChannel
parameters and its function.
"""
function Base.show(io::IO, ref::DeferredChannel)
    rc = ref.outer
    print(
        io,
        "$(typeof(ref).name.name)($(ref.func)) at ($(rc.where),$(rc.whence),$(rc.id))"
    )
end

"""
    serialize(s::AbstractSerializer, ref::DeferredChannel)

Serialize a DeferredChannel such that it can de deserialized by `deserialize` in a cluster.
"""
function serialize(s::AbstractSerializer, ref::DeferredChannel)
    serialize_cycle(s, ref) && return

    serialize_type(s, DeferredChannel, true)
    serialize_any(s, ref.outer)
    serialize(s, ref.func)
end

"""
    finalize_ref(ref::DeferredRemoteRef)

This finalizer is attached to both `DeferredFuture` and `DeferredChannel` on construction
and finalizes the inner and outer `RemoteChannel`s.

For more information on finalizing remote references, see the Julia manual[^1].

[^1]: [Remote References and Distributed Garbage Collection](http://docs.julialang.org/en/latest/manual/parallel-computing.html#Remote-References-and-Distributed-Garbage-Collection-1)
"""
function finalize_ref(ref::DeferredRemoteRef)
    # finalizes as recommended in Julia docs:
    # http://docs.julialang.org/en/latest/manual/parallel-computing.html#Remote-References-and-Distributed-Garbage-Collection-1

    # check for ref.outer.where == 0 as the contained RemoteChannel may have already been
    # finalized
    if ref.outer.where > 0 && isready(ref.outer)
        inner = take!(ref.outer)

        finalize(inner)
    end

    finalize(ref.outer)

    return nothing
end

"""
    reset!{T<:DeferredRemoteRef}(ref::T) -> T

Removes any data from the `DeferredRemoteRef` and allows it to be reinitialized with data.

Returns the input `DeferredRemoteRef`.
"""
function reset!(ref::DeferredRemoteRef)
    if isready(ref.outer)
        inner = take!(ref.outer)

        # as recommended in Julia docs:
        # http://docs.julialang.org/en/latest/manual/parallel-computing.html#Remote-References-and-Distributed-Garbage-Collection-1
        finalize(inner)
    end

    return ref
end

"""
    put!(ref::DeferredFuture, v) -> DeferredFuture

Store a value to a `DeferredFuture`. `DeferredFuture`s, like `Future`s, are write-once
remote references. A `put!` on an already set `DeferredFuture` throws an `Exception`.
Returns its first argument.
"""
function Base.put!(ref::DeferredFuture, val)
    if !isready(ref.outer)
        inner = RemoteChannel()
        put!(ref.outer, inner)
        put!(fetch(ref.outer), val)

        return ref
    else
        throw(ErrorException("DeferredFuture can only be set once."))
    end
end

"""
    put!(rr::DeferredChannel, val) -> DeferredChannel

Store a value to the `DeferredChannel`. If the channel is full, blocks until space is
available. Returns its first argument.
"""
function Base.put!(ref::DeferredChannel, val)
    # On the first call to `put!` create the `RemoteChannel` and `put!` it in the `Future`
    if !isready(ref.outer)
        inner = RemoteChannel(ref.func)
        put!(ref.outer, inner)
    end

    # `fetch` the `RemoteChannel` and `put!` the value in there
    put!(fetch(ref.outer), val)

    return ref
end

"""
    isready(ref::DeferredRemoteRef) -> Bool

Determine whether a `DeferredRemoteRef` has a value stored to it. Note that this function
can cause race conditions, since by the time you receive its result it may no longer be
true.
"""
function Base.isready(ref::DeferredRemoteRef)
    isready(ref.outer) && isready(fetch(ref.outer))
end

"""
    fetch(ref::DeferredRemoteRef) -> Any

Wait for and get the value of a remote reference.
"""
function Base.fetch(ref::DeferredRemoteRef)
    fetch(fetch(ref.outer))
end

"""
    wait(ref::DeferredRemoteRef) -> DeferredRemoteRef

Block the current task until a value becomes available on the `DeferredRemoteRef`. Returns
its first argument.
"""
function Base.wait(ref::DeferredRemoteRef)
    wait(ref.outer)
    wait(fetch(ref.outer))
    return ref
end

# mimics the Future/RemoteChannel indexing behaviour in Base
Base.getindex(ref::DeferredRemoteRef, args...) = getindex(fetch(ref.outer), args...)

"""
    close(ref::DeferredChannel)

Closes a `DeferredChannel`. An exception is thrown by:
* `put!` on a closed `DeferredChannel`
* `take!` and `fetch` on an empty, closed `DeferredChannel`
"""
function Base.close(ref::DeferredChannel)
    if isready(ref.outer)
        inner = fetch(ref.outer)
        close(inner)
    else
        rc = RemoteChannel()
        close(rc)

        put!(ref.outer, rc)
    end

    return nothing
end

"""
    take!(ref::DeferredChannel, args...)

Fetch value(s) from a `DeferredChannel`, removing the value(s) in the processs. Note that
`take!` passes through `args...` to the innermost `AbstractChannel` and the default
`Channel` accepts no `args...`.
"""
Base.take!(ref::DeferredChannel, args...) = take!(fetch(ref.outer), args...)

"""
    @defer Future(...)
    @defer RemoteChannel(...)

`@defer` transforms a `Future` or `RemoteChannel` construction into a 'DeferredFuture' or
'DeferredChannel' construction.
"""
macro defer(ex::Expr)
    if ex.head != :call
        throw(AssertionError("Expected expression to be a function call, but got $(ex)."))
    end

    if ex.args[1] == :Future
        return Expr(:call, :DeferredFuture, ex.args[2:end]...)
    elseif ex.args[1] == :RemoteChannel
        return Expr(:call, :DeferredChannel, ex.args[2:end]...)
    else
        throw(AssertionError("Expected RemoteChannel or Future and got $(ex.args[1])."))
    end
end

end # module
