export LocalComm

#This class is to create a stand in for Tpetra's local maps

"""
    LocalComm(::Comm{GID, PID, LID})

Creates a comm object that creates an error when inter-process communication is attempted, but still allows access to the correct process ID information
"""
struct LocalComm{GID <: Integer, PID <: Integer, LID <: Integer} <: Comm{GID, PID, LID}
    original::Comm{GID, PID, LID}
end


function barrier(comm::LocalComm)
    throw(InvalidStateError("Cannot call barrier on a local comm"))
end

function broadcastAll(comm::LocalComm, v::AbstractArray, root::Integer)
    throw(InvalidStateError("Cannot call broadcastAll on a local comm"))
end

function gatherAll(comm::LocalComm, v::AbstractArray)
    throw(InvalidStateError("Cannot call gatherAll on a local comm"))
end

function sumAll(comm::LocalComm, v::AbstractArray)
    throw(InvalidStateError("Cannot call sumAll on a local comm"))
end

function maxAll(comm::LocalComm, v::AbstractArray)
    throw(InvalidStateError("Cannot call maxAll on a local comm"))
end

function minAll(comm::LocalComm, v::AbstractArray)
    throw(InvalidStateError("Cannot call minAll on a local comm"))
end

function scanSum(comm::LocalComm, v::AbstractArray)
    throw(InvalidStateError("Cannot call scanSum on a local comm"))
end

function myPid(comm::LocalComm)
    myPid(comm.original)
end

function numProc(comm::LocalComm)
    numProc(comm.original)
end

function createDistributor(comm::LocalComm)
    throw(InvalidStateError("Cannot call createDistributor on a local comm"))
end