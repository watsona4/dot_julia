module Semaphores

using Serialization
using Base.Filesystem

import Base: lock, trylock, unlock, close, delete!, count, reset
import Serialization: serialize, deserialize

export NamedSemaphore, ResourceCounter, SemBuf
export lock, trylock, unlock, close, delete!, count, reset, change, withlock, serialize, deserialize

include("named_semaphore.jl")
include("sysv_semaphore.jl")
include("resource_counter.jl")

function withlock(f, lck)
    lock(lck)
    try
        f()
    finally
        unlock(lck)
    end
end

end # module
