export Comm
export barrier, broadcastAll, gatherAll, sumAll, maxAll, minAll, scanSum
export myPid, numProc, createDistributor
export getComm

# methods (and docs) are currently based straight off Epetra_Comm
# tpetra's equivalent seemed to be a wrapper to other Trilinos packages

# following julia's convention, n processors are labled 1 through n
# count variables are removed, since that information is contained in the arrays

"""
The base type for types that represent communication in parallel computing.

All subtypes must have the following methods, with CommImpl standing in for the subtype:

    barrier(comm::CommImpl)
Each processor must wait until all processors have arrived

    broadcastAll(comm::CommImpl, myvals::AbstractArray{T}, Root::Integer)::Array{T} where T
Takes a list of input values from the root processor and sends to all
other processors.  The values are returned (including on the root process)

    gatherAll(comm::CommImpl, myVals::AbstractArray{T})::Array{T} where T
Takes a list of input values from all processors and returns an ordered
contiguous list of those values on each processor

    sumAll(comm::CommImpl, partialsums::AbstractArray{T})::Array{T} where T
Take a list of input values from all processors and returns the sum on each
processor.  The method +(::T, ::T)::T can be assumed to exist

    maxAll(comm::CommImpl, partialmaxes::AbstractArray{T})::Array{T} where T
Takes a list of input values from all processors and returns the max to all
processors.  The method <(::T, ::T)::Bool can be assumed to exist

    minAll(comm::CommImpl, partialmins::AbstractArray{T})::Array{T} where T
Takes a list of input values from all processors and returns the min to all
processors.  The method <(::T, ::T)::Bool can be assumed to exist

    scanSum(comm::CommImpl, myvals::AbstractArray{T})::Array{T} where T
Takes a list of input values from all processors, computes the scan sum and
returns it to all processors such that processor i contains the sum of
values from processor 1 up to and including processor i.  The method
`+(::T, ::T)::T` is used for the addition.

    myPid(comm::CommImpl{GID, PID, LID})::PID
Returns the process rank

    numProc(comm::CommImpl{GID, PID, LID})::PID
Returns the total number of processes

    createDistributor(comm::CommImpl{GID, PID, LID})::Distributor{GID, PID, LID}
Create a distributor object

"""
abstract type Comm{GID <: Integer, PID <:Integer, LID <: Integer}
end

function Base.show(io::IO, comm::Comm)
    print(io, String(Symbol(typeof(comm))), " with PID ", myPid(comm),
                " and ", numProc(comm), " processes")
end

"""
    broadcastAll(::Comm, myVals::T, root::Integer)::T
    broadcastAll(comm::Comm, myVals::AbstractArray{T, 1}, root::Integer)::Array{T, 1}

Takes a list of input values from the root processor and sends it to each
other processor.  The broadcasted values are then returned, including on
the root process.
"""
broadcastAll(comm::Comm, myVal, root) = broadcastAll(comm, [myVal], root)[1]

"""
    gatherAll(::Comm, myVal::T)::Array{T, 1}
    gatherAll(comm::Comm, myVals::AbstractArray{T, 1})::Array{T, 1}

Takes a list of input values from all processors and returns an ordered,
contiguous list of those values.
"""
gatherAll(comm::Comm, myVal) = gatherAll(comm, [myVal])

"""
    sumAll(::Comm, partialsum::T)::T
    sumAll(comm::Comm, partialsums::AbstractArray{T, 1})::Array{T, 1}

Takes a list of input values from all processors and returns the sum on each
processor.  The method `+(::T, ::T)::T` must exist.
"""
sumAll(comm::Comm, val) = sumAll(comm, [val])[1]

"""
    maxAll(::Comm, partialmax::T)::T
    maxAll(comm::Comm, partialmaxes::AbstractArray{T, 1})::Array{T, 1}

Takes a list of input values from all processors and returns the max to all
processors.  The method `<(::T, ::T)::Bool` must exist.
"""
maxAll(comm::Comm, val) = maxAll(comm, [val])[1]

"""
    minAll(::Comm, partialmin::T)::T
    minAll(comm::Comm, partialmins::AbstractArray{T, 1})::Array{T, 1}

Takes a list of input values from all processors and returns the min to all
processors.  The method `<(::T, ::T)::Bool` must exist.
"""
minAll(comm::Comm, val) = minAll(comm, [val])[1]

"""
    scanSum(::Comm, myval::T)::T
    scanSum(comm::Comm, myvals::AbstractArray{T, 1})::Array{T, 1}

Takes a list of input values from all processors, computes the scan sum and
returns it to all processors such that processor `i` contains the sum of
values from processor 1 up to, and including, processor `i`.  The method
+(::T, ::T)::T must exist
"""
scanSum(comm::Comm, val) = scanSum(comm, [val])[1]

"""
    getComm(obj)

Gets the Comm for the object, if applicable
"""
getComm(comm::Comm) = comm


#### documentation for required methods ####

"""
    barrier(::Comm)

Causes the process to pause until all processes have called barrier.  Used to synchronize the processes
"""
function barrier end


"""
    myPid(::Comm{GID, PID, LID})::PID

Returns the rank of the calling processor
"""
function myPid end

"""
    numProc(::Comm{GID, PID, LID})::PID

Returns the total number of processes
"""
function numProc end

"""
    createDistributor(comm::Comm{GID, PID, LID})::Distributor{GID, PID, LID}

Creates a distributor for the given Comm object
"""
function createDistributor end
