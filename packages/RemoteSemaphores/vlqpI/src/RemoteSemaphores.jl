module RemoteSemaphores

export RemoteSemaphore, acquire, release

using Base: Semaphore, acquire, release
using Distributed

"""
    RemoteSemaphore(n::Int, pid=myid())

A semaphore living on a specific process.
Do not attempt to fetch the future to a different process and use it there, as that will be
an isolated, unsynced copy of the semaphore.
"""
struct RemoteSemaphore
    n::Int  # stored for printing only
    rref::Future

    function RemoteSemaphore(n::Integer, pid=myid())
        sem = Semaphore(n)
        fut = Future(pid)
        put!(fut, sem)

        return new(n, fut)
    end
end

function Base.acquire(rsem::RemoteSemaphore)
    fut = rsem.rref
    loc = fut.where
    remotecall_wait(loc) do
        sem = fetch(fut)
        acquire(sem)
    end

    return nothing
end

function Base.release(rsem::RemoteSemaphore)
    fut = rsem.rref
    loc = fut.where
    remotecall_wait(loc) do
        sem = fetch(fut)
        release(sem)
    end

    return nothing
end

function Base.show(io::IO, rsem::RemoteSemaphore)
    print(io, typeof(rsem), '(', rsem.n, ", pid=", rsem.rref.where, ')')
end

# expensive, easily out of sync, for testing only
function _current_count(rsem::RemoteSemaphore)
    fut = rsem.rref
    loc = fut.where

    return remotecall_fetch(loc) do
        sem = fetch(fut)
        return sem.curr_cnt
    end
end

end
