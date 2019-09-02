
export SerialComm, SerialDistributor

"""
    SerialDistributor()

Creates a distributor to work with SerialComm
"""
mutable struct SerialDistributor{GID <: Integer, PID <:Integer, LID <: Integer} <: Distributor{GID, PID, LID}
    post::Union{AbstractArray, Nothing}
    reversePost::Union{AbstractArray, Nothing}

    function SerialDistributor{GID, PID, LID}() where GID <: Integer where PID <: Integer where LID <: Integer
        new(nothing, nothing)
    end
end


function createFromSends(dist::SerialDistributor{GID, PID, LID},
        exportPIDs::AbstractArray{PID})::Integer where GID <: Integer where PID <: Integer where LID <: Integer
    for id in exportPIDs
        if id != 1
            throw(InvalidArgumentError("SerialDistributor can only accept PID of 1"))
        end
    end
    length(exportPIDs)
end

function createFromRecvs(
        dist::SerialDistributor{GID, PID, LID}, remoteGIDs::AbstractArray{GID}, remotePIDs::AbstractArray{PID}
        )::Tuple{AbstractArray{GID}, AbstractArray{PID}} where GID <: Integer where PID <: Integer where LID <: Integer
    for id in remotePIDs
        if id != 1
            throw(InvalidArgumentError("SerialDistributor can only accept PID of 1"))
        end
    end
    remoteGIDs,remotePIDs
end

function resolve(dist::SerialDistributor, exportObjs::AbstractArray{T})::AbstractArray{T} where T
    exportObjs
end

function resolveReverse(dist::SerialDistributor, exportObjs::AbstractArray{T})::AbstractArray{T} where T
    exportObjs
end

function resolvePosts(dist::SerialDistributor, exportObjs::AbstractArray)
    dist.post = exportObjs
end

function resolveWaits(dist::SerialDistributor)::AbstractArray
    if dist.post == nothing
        throw(InvalidStateError("Must post before waiting"))
    end

    result = dist.post
    dist.post = nothing
    result
end

function resolveReversePosts(dist::SerialDistributor, exportObjs::AbstractArray)
    dist.reversePost = exportObjs
end

function resolveReverseWaits(dist::SerialDistributor)::AbstractArray
     if dist.reversePost == nothing
        throw(InvalidStateError("Must reverse post before reverse waiting"))
    end

    result = dist.reversePost
    dist.reversePost = nothing
    result
end



"""
    SerialComm()

Gets an serial communication instance.
Serial communication results in mostly no-ops for the communication operations
"""
struct SerialComm{GID <: Integer, PID <:Integer, LID <: Integer} <: Comm{GID, PID, LID}
end


# most of these functions are no-ops or identify functions since there is only
# one processor

function barrier(comm::SerialComm)
end


function broadcastAll(comm::SerialComm, myVals::AbstractArray{T}, root::Integer)::Array{T} where T
    if root != 1
        throw(InvalidArgumentError("SerialComm can only accept PID of 1"))
    end
    myVals
end

function gatherAll(comm::SerialComm, myVals::AbstractArray{T})::Array{T} where T
    myVals
end

function sumAll(comm::SerialComm, partialsums::AbstractArray{T})::Array{T} where T
    partialsums
end

function maxAll(comm::SerialComm, partialmaxes::AbstractArray{T})::Array{T} where T
    partialmaxes
end

function minAll(comm::SerialComm, partialmins::AbstractArray{T})::Array{T} where T
    partialmins
end

function scanSum(comm::SerialComm, myvals::AbstractArray{T})::Array{T} where T
    myvals
end

function myPid(comm::SerialComm{GID, PID})::PID where GID <: Integer where PID <: Integer
    1
end

function numProc(comm::SerialComm{GID, PID})::PID where GID <: Integer where PID <: Integer
    1
end

function createDistributor(comm::SerialComm{GID, PID, LID})::SerialDistributor{GID, PID, LID} where GID <: Integer where PID <: Integer where LID <: Integer
    SerialDistributor{GID, PID, LID}()
end

getComm(::SerialDistributor{GID, PID, LID}) where {GID, PID, LID} = SerialComm{GID, PID, LID}()
