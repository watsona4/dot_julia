

export Distributor
export createFromSends, createFromRecvs
export resolve, resolveReverse, resolveWaits
export resolvePosts, resolveReversePosts, resolveReverseWaits

# methods (and docs) are currently based straight off Epetra_Distributor to match Comm

"""
The base type for gather/scatter setup.
All subtypes must have the following methods, with DistributorImpl standing
in for the subtype:

    createFromSends(dist::DistributorImpl,exportPIDs::AbstractArray{PID})::Integer where PID <:Integer
Sets up the Distributor object using a list of process IDs to which we
export.  Returns the number of IDs this processor will be receiving.

    createFromRecvs(dist::DistributorImpl, remoteGIDs::AbstractArray{GID}, remotePIDs::AbstractArray{PID})::Tuple{AbstractArray{GID}, AbstractArray{PID}} where GID <: Integer where PID <: Integer
Sets up the Distributor object using a list of remote global IDs and corresponding
PIDs.  Returns a tuple with the global IDs and their respective processor IDs
being sent by this processor.

    resolvePosts(dist::DistributorImpl, exportObjs::AbstractArray)
Post buffer of export objects.  Other, local work can be done before resolving
the waits.  Otherwise, as [`resolve`](@ref).

    resolveWaits(dist::DistributorImpl)::AbstractArray
Wait on a set of posts

    resolveReversePosts(dist::DistributorImpl, exportObjs::AbstractArray)
Do reverse post of buffer of export objects Other, local work can be done before
resolving the waits.  Otherwise, as
[`resolveReverse`](@ref).

    resolveReverseWaits(dist::DistributorImpl)::AbstractArray
Wait on a set of reverse posts.

"""
abstract type Distributor{GID <: Integer, PID <: Integer, LID <: Integer}
end

"""
    createFromSends(dist::Distributor, exportPIDs::AbstractArray{<:Integer})::Integer

Sets up the Distributor object using a list of process IDs to which we
export and the number of IDs being exported.  Returns the number of
IDs this processor will be receiving
"""
function createFromSends(dist::Distributor{GID, PID, LID}, exportPIDs::AbstractArray{<:Integer}) where GID <: Integer where PID <: Integer where LID <: Integer
    createFromSends(dist, Array{PID}(exportPIDs))
end

"""
    createFromRecvs(dist::Distributor{GID, PID, LID}, remoteGIDs::AbstractArray{<:Integer}, remotePIDs::AbstractArray{<:Integer})::Tuple{AbstractArray{GID}, AbstractArray{PID}}

Sets up the Distributor object using a list of remote global IDs and
corresponding PIDs.  Returns a tuple with the global IDs and their
respective processor IDs being sent by me.
"""
function createFromRecvs(dist::Distributor{GID, PID, LID}, remoteGIDs::AbstractArray{<:Integer},
        remotePIDs::AbstractArray{<:Integer}) where GID <: Integer where PID <: Integer where LID <: Integer
    createFromRecvs(dist, Array{GID}(remoteGIDs), Array{PID}(remotePIDs))
end

"""
    resolve(dist::Distributor, exportObjs::AbstractArray{T})::AbstractArray{T}

Execute the current plan on buffer of export objects and return the
objects set to this processor
"""
function resolve(dist::Distributor, exportObjs::AbstractArray{T})::AbstractArray{T} where T
    resolvePosts(dist, exportObjs)
    resolveWaits(dist)::AbstractArray{T}
end

"""
    resolveReverse(dist::Distributor, exportObjs::AbstractArray{T})::AbstractArray{T}

Execute the reverse of the current plan on buffer of export objects and
return the objects set to this processor
"""
function resolveReverse(dist::Distributor, exportObjs::AbstractArray{T})::AbstractArray{T} where T
    resolveReversePosts(dist, exportObjs)
    resolveReverseWaits(dist)
end


#### required method documentation stubs ####

"""
    resolvePosts(dist::Distributor, exportObjs::AbstractArray)

Post buffer of export objects.  Other, local work can be done before resolving
the waits.  Otherwise, as [`resolve`](@ref).
"""
function resolvePosts end

"""
    resolveWaits(dist::Distributor)::AbstractArray

Wait on a set of posts.
"""
function resolveWaits end

"""
    resolveReversePosts(dist::Distributor, exportObjs::AbstractArray)
Do reverse post of buffer of export objects Other, local work can be done before
resolving the waits.  Otherwise, as
[`resolveReverse`](@ref).
"""
function resolveReversePosts end

"""
    resolveReverseWaits(dist::Distributor)::AbstractArray

Wait on a set of reverse posts.
"""
function resolveReverseWaits end
