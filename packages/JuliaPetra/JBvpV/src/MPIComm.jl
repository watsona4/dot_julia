
import MPI

export MPIComm

"""
    MPIComm()
    MPIComm(comm::MPI.Comm)

An implementation of Comm using MPI
The no argument constructor uses MPI.COMM_WORLD
"""
struct MPIComm{GID <: Integer, PID <:Integer, LID <: Integer} <: Comm{GID, PID, LID}
    mpiComm::MPI.Comm
end

function MPIComm(GID::Type, PID::Type, LID::Type)
    MPIInit()
    comm = MPIComm{GID, PID, LID}(MPI.COMM_WORLD)

    comm
end

MPINeedsInitialization = true

"""
    MPIInit()

On the first call, initializes MPI and adds an exit hook to finalize MPI
Does nothing on subsequent calls
"""
function MPIInit()
    global MPINeedsInitialization
    if MPINeedsInitialization
        MPI.Init()
        atexit(() -> MPI.Finalize())

        MPINeedsInitialization = false
    end
end

function barrier(comm::MPIComm)
    MPI.Barrier(comm.mpiComm)
end

function broadcastAll(comm::MPIComm, myvals::AbstractArray{T}, root::Integer)::Array{T} where T
    vals = copy(myvals)
    result = MPI.Bcast!(vals, root-1, comm.mpiComm)
    result
end

function gatherAll(comm::MPIComm, myVals::AbstractArray{T})::Array{T} where T
    lengths = MPI.Allgather([convert(Cint, length(myVals))], comm.mpiComm)
    MPI.Allgatherv(myVals, lengths, comm.mpiComm)
end

function sumAll(comm::MPIComm, partialsums::AbstractArray{T})::Array{T} where T
    MPI.allreduce(partialsums, +, comm.mpiComm)
end

function maxAll(comm::MPIComm, partialmaxes::AbstractArray{T})::Array{T} where T
    MPI.allreduce(partialmaxes, max, comm.mpiComm)
end

function maxAll(comm::MPIComm, partialmaxes::AbstractArray{Bool})::Array{Bool}
    Array{Bool}(maxAll(comm, Array{UInt8}(partialmaxes)))
end

function minAll(comm::MPIComm, partialmins::AbstractArray{T})::Array{T} where T
    MPI.allreduce(partialmins, min, comm.mpiComm)
end

function minAll(comm::MPIComm, partialmins::AbstractArray{Bool})::Array{Bool}
    Array{Bool}(minAll(comm, Array{UInt8}(partialmins)))
end

function scanSum(comm::MPIComm, myvals::AbstractArray{T})::Array{T} where T
    MPI.Scan(myvals, length(myvals), MPI.SUM, comm.mpiComm)
end

function myPid(comm::MPIComm{GID, PID})::PID where {GID <: Integer, PID <: Integer}
    MPI.Comm_rank(comm.mpiComm) + 1
end

function numProc(comm::MPIComm{GID, PID})::PID where {GID <: Integer, PID <:Integer}
    MPI.Comm_size(comm.mpiComm)
end

function createDistributor(comm::MPIComm{GID, PID, LID})::MPIDistributor{GID, PID, LID}  where {GID <: Integer, PID <: Integer, LID <: Integer}
    MPIDistributor(comm)
end
