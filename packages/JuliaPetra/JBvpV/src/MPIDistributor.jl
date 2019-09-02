
import MPI
using Serialization

export MPIDistributor

"""
    MPIDistributor{GID, PID, LID}(comm::MPIComm{GID, PID, LID})
Creates an Distributor to work with MPIComm.  Created by
createDistributor(::MPIComm{GID, PID, LID})
"""
mutable struct MPIDistributor{GID <: Integer, PID <: Integer, LID <: Integer} <: Distributor{GID, PID, LID}
    comm::MPIComm{GID, PID, LID}

    lengths_to::Vector{GID}
    procs_to::Vector{PID}
    indices_to::Vector{GID}

    lengths_from::Vector{GID}
    procs_from::Vector{PID}
    indices_from::Vector{GID}

    resized::Bool
    sizes::Vector{GID}

    sizes_to::Vector{GID}
    starts_to::Vector{GID}
    #starts_to_ptr::Array{Integer}
    #indices_to_ptr::Array{Integer}

    sizes_from::Vector{GID}
    starts_from::Vector{GID}
    #sizes_from_ptr::Array{Integer}
    #starts_from_ptr::Array{Integer}

    numRecvs::GID
    numSends::GID
    numExports::GID

    selfMsg::GID

    maxSendLength::GID
    totalRecvLength::GID

    request::Vector{MPI.Request}
    status::Vector{MPI.Status}

    #sendArray::Array{UInt8}

    planReverse::Union{MPIDistributor{GID, PID, LID}, Nothing}

    importObjs::Union{Vector{<:Vector}, Nothing}

    datatype::DataType

    #never seem to be used
    #lastRoundBytesSend::Integer
    #lastRoundBytesRecv::Integer

    function MPIDistributor(comm::MPIComm{GID, PID, LID}) where GID <: Integer where PID <: Integer where LID <: Integer
        new{GID, PID, LID}(comm, [], [], [], [], [], [], false, [], [], [], [], [],
            0, 0, 0, 0, 0, 0, [], [],  nothing,
            nothing, Nothing)
    end
end


#### internal methods ####
function createSendStructure(dist::MPIDistributor{GID, PID, LID}, pid::PID,
        nProcs::PID, exportPIDs::AbstractArray{PID}
        ) where {GID <: Integer, PID <: Integer, LID <: Integer}

    numExports = length(exportPIDs)
    dist.numExports = numExports

    starts = zeros(GID, nProcs+1)

    nactive = 0
    noSendBuff = true
    numDeadIndices::GID = 0  #for GIDs not owned by any processors

    for i = 1:numExports
        if noSendBuff && i > 1 && exportPIDs[i] < exportPIDs[i-1]
            noSendBuff = false
        end
        if exportPIDs[i] >= 1
            starts[exportPIDs[i]] += 1
            nactive += 1
        else
            numDeadIndices += 1
        end
    end

    dist.selfMsg = starts[pid] != 0
    dist.numSends = 0

    if noSendBuff #grouped by processor, no send buffer or indices_to needed
        for i = 1:nProcs
            if starts[i] > 0
                dist.numSends += 1
            end
        end

        dist.procs_to = Vector{PID}(undef, dist.numSends)
        dist.starts_to = Vector{GID}(undef, dist.numSends)
        dist.lengths_to = Vector{GID}(undef, dist.numSends)

        index = numDeadIndices+1
        for i = 1:dist.numSends
            dist.starts_to[i] = index
            proc = exportPIDs[index]
            dist.procs_to[i] = proc
            index += starts[proc]
        end

        perm = sortperm(dist.procs_to)
        dist.procs_to = dist.procs_to[perm]
        dist.starts_to = dist.starts_to[perm]

        # line 430

        dist.maxSendLength = 0

        for i = 1:dist.numSends
            proc = dist.procs_to[i]
            dist.lengths_to[i] = starts[proc]
            if (proc != pid) && (dist.lengths_to[i] > dist.maxSendLength)
                maxSendLength = dist.lengths_to[i]
            end
        end
    else #not grouped by processor, need send buffer and indices_to
        if starts[1] != 0
            dist.numSends = 1
        end

        for i = 2:nProcs
            if starts[i] != 0
                dist.numSends += 1
            end
            starts[i] += starts[i-1]
        end

        for i = nProcs:-1:2
            starts[i] = starts[i-1] + 1
        end
        starts[1] = 1

        if nactive > 0
            dist.indices_to = Array{GID, 1}(undef, nactive)
        end


        for i = 1:numExports
            if exportPIDs[i] >= 1
                dist.indices_to[starts[exportPIDs[i]]] = i
                starts[exportPIDs[i]] += 1
            end
        end

        #reconstruct starts array to index into indices_to

        for i = nProcs:-1:2
            starts[i] = starts[i-1]
        end
        starts[1] = 1
        starts[nProcs+1] = nactive+1


        if dist.numSends > 0
            dist.lengths_to = Vector{GID}(undef, dist.numSends)
            dist.procs_to = Vector{PID}(undef, dist.numSends)
            dist.starts_to = Vector{GID}(undef, dist.numSends)
        end

        j::GID = 1
        dist.maxSendLength = 0
        for i = 1:nProcs
            if starts[i+1] != starts[i]
                dist.lengths_to[j] = starts[i+1] - starts[i]
                dist.starts_to[j] = starts[i]
                if (i != pid) && (dist.lengths_to[j] > dist.maxSendLength)
                    dist.maxSendLength = dist.lengths_to[j]
                end
                dist.procs_to[j] = i
                j += 1
            end
        end
    end

    dist.numSends -= dist.selfMsg

    dist
end


function computeRecvs(dist::MPIDistributor{GID, PID, LID}, myProc::PID, nProcs::PID) where GID <: Integer where PID <: Integer where LID <: Integer

    msgCount = zeros(Int, nProcs)

    for proc in dist.procs_to
        msgCount[proc] += 1
    end

    #bug fix for reduce-scatter bug applied since no reduce_scatter is present in julia's MPI
    rawCounts = MPI.Reduce(msgCount, MPI.SUM, 0, dist.comm.mpiComm)
    if rawCounts isa Nothing
        counts = Int[]
    else
        counts = rawCounts
    end
    totalRecvs = MPI.Scatter(counts, 1, 0, dist.comm.mpiComm)[1]

    dist.lengths_from = zeros(Int, totalRecvs)
    dist.procs_from = zeros(PID, totalRecvs)

    #using NEW_COMM_PATTERN (see line 590)

    if dist.request == []
        dist.request = Vector{MPI.Request}(undef, totalRecvs - dist.selfMsg)
    end

    #line 616

    lengthWrappers = [Array{Int, 1}(undef, 1) for i in 1:(totalRecvs - dist.selfMsg)]
    for i = 1:(totalRecvs - dist.selfMsg)
        dist.request[i] = MPI.Irecv!(lengthWrappers[i], MPI.ANY_SOURCE, MPI.ANY_TAG, dist.comm.mpiComm)
    end

    barrier(dist.comm)

    for i = 1:(dist.numSends+dist.selfMsg)
        if dist.procs_to[i] != myProc
            #have to use Rsend in MPIUtil
            MPI_Rsend(dist.lengths_to[i], dist.procs_to[i]-1, 1, dist.comm.mpiComm)
        else
            dist.lengths_from[totalRecvs] = dist.lengths_to[i]
            dist.procs_from[totalRecvs] = myProc
        end
    end

    if totalRecvs > dist.selfMsg
        dist.status = MPI.Waitall!(dist.request)
    end

    for i = 1:(totalRecvs - dist.selfMsg)
        dist.lengths_from[i] = lengthWrappers[i][1]
    end


    for i = 1:(totalRecvs - dist.selfMsg)
        dist.procs_from[i] = MPI.Get_source(dist.status[i])+1
    end

    perm = sortperm(dist.procs_from)
    dist.procs_from = dist.procs_from[perm]
    dist.lengths_from = dist.lengths_from[perm]

    dist.starts_from = Vector{GID}(undef, totalRecvs)
    j = GID(1)
    for i = 1:totalRecvs
        dist.starts_from[i] = j
        j += dist.lengths_from[i]
    end

    dist.totalRecvLength = 0
    for i = 1:totalRecvs
        dist.totalRecvLength += dist.lengths_from[i]
    end

    dist.numRecvs = totalRecvs - dist.selfMsg

    dist
end

function computeSends(dist::MPIDistributor{GID, PID, LID},
        remoteGIDs::AbstractArray{GID, 1}, remotePIDs::AbstractArray{PID, 1}
        )::Tuple{AbstractArray{GID, 1}, AbstractArray{PID, 1}
        } where {GID <:Integer, PID <:Integer, LID <:Integer}
    numImports = length(remoteGIDs)

    tmpPlan = MPIDistributor(dist.comm)

    importObjs = Vector{Tuple{GID, PID}}(undef, numImports)
    for i = 1:numImports
        importObjs[i] = (remoteGIDs[i], myPid(dist.comm))#remotePIDs[i])
    end

    numExports = createFromSends(tmpPlan, copy(remotePIDs))

    exportIDs = Vector{GID}(undef, numExports)
    exportProcs = Vector{PID}(undef, numExports)

    exportObjs = resolve(tmpPlan, importObjs)
    for i = 1:numExports
        exportIDs[i] = exportObjs[i][1]
        exportProcs[i] = exportObjs[i][2]
    end
    (exportIDs, exportProcs)
end

"""
Creates a reverse distributor for the given MPIDistributor
"""
function createReverseDistributor(dist::MPIDistributor{GID, PID, LID}
        ) where {GID <: Integer, PID <: Integer, LID <: Integer}
    myProc = myPid(dist.comm)

    if dist.planReverse == nothing
        totalSendLength = reduce(+, dist.lengths_to)

        maxRecvLength::GID = 0
        for i = 1:dist.numRecvs
            if dist.procs_from[i] != myProc
                maxRecvLength = max(maxRecvLength, dist.lengths_from[i])
            end
        end

        reverse = MPIDistributor(dist.comm)
        dist.planReverse = reverse

        reverse.lengths_to = dist.lengths_from
        reverse.procs_to = dist.procs_from
        reverse.indices_to = dist.indices_from
        reverse.starts_to = dist.starts_from

        reverse.lengths_from = dist.lengths_to
        reverse.procs_from = dist.procs_to
        reverse.indices_from = dist.indices_to
        reverse.starts_from = dist.starts_to

        reverse.numSends = dist.numRecvs
        reverse.numRecvs = dist.numSends
        reverse.selfMsg = dist.selfMsg

        reverse.maxSendLength = maxRecvLength
        reverse.totalRecvLength = totalSendLength

        reverse.request = Vector{MPI.Request}(undef, reverse.numRecvs)
        reverse.status  = Vector{MPI.Status}(undef, reverse.numRecvs)
    end

    nothing
end


#### Internal Utilities ####
"""
    arraytobytes(value::Vector{T})::Vector{UInt8}

Converts the given vector to a list of bytes.
"""
function arraytobytes(value::AbstractVector{T}) where T
    if isbitstype(T)
        # if T is a bits type, then just use the buffer as it
        sz = sizeof(value)
        bytes_ptr = convert(Ptr{UInt8}, Base.unsafe_convert(Ptr{T}, value))
        unsafe_wrap(Array, bytes_ptr, sz)
    else
        # otherwise write using an IOBuffer
        buffer = IOBuffer(;sizehint=sizeof(value))
        write(buffer, value)
        take!(buffer)
    end
end

function arraytobytes(value::AbstractVector{<:AbstractVector})
    buffer = IOBuffer()
    for v in value
        write(buffer, UInt32(length(v)))
        for elt in v
            write(buffer, elt)
        end
    end
    take!(buffer)
end


"""
    bytestoarray(bytes::Vector{UInt8}, ::Type{T})::Vector{T} where T

Converts a list of bytes to a vector with contents of the given type
"""
function bytestoarray(bytes::AbstractVector{UInt8}, ::Type{T}) where T
    sz = fld(length(bytes), sizeof(T))
    value = Vector{T}(undef, sz)
    if isbitstype(T)
        bytes_ptr = convert(Ptr{T}, Base.unsafe_convert(Ptr{UInt8}, bytes))
        value_ptr = Base.unsafe_convert(Ptr{T}, value)
        Base.unsafe_copyto!(value_ptr, bytes_ptr, sz)
    else
        buffer = IOBuffer(bytes)
        i = 1
        while !eof(buffer)
            value[i] = read(buffer, T)
            i+=1
        end
    end
    value
end


function bytestoarray(bytes::AbstractVector{UInt8}, ::Type{Vector{T}}) where T
    buffer = IOBuffer(bytes)
    value = Vector{Vector{T}}()
    while !eof(buffer)
        len = read(buffer, UInt32)
        elt = Vector{T}(undef, len)
        for i in 1:len
            elt[i] = read(buffer, T)
        end
        push!(value, elt)
    end
    value
end


#### General Interface ####

getComm(dist::MPIDistributor) = dist.comm

#### Distributor interface ####

function createFromSends(dist::MPIDistributor{GID, PID, LID}, exportPIDs::AbstractArray{PID, 1})::Integer where GID <:Integer where PID <:Integer where LID <:Integer
    pid = myPid(dist.comm)
    nProcs = numProc(dist.comm)
    createSendStructure(dist, pid, nProcs, exportPIDs)
    computeRecvs(dist, pid, nProcs)
    if dist.numRecvs > 0
        if dist.request == []
            dist.request = Vector{MPI.Request}(undef, dist.numRecvs)
            dist.status = Vector{MPI.Status}(undef, dist.numRecvs)
        end
    end
    dist.totalRecvLength
end


function createFromRecvs(dist::MPIDistributor{GID, PID, LID},
        remoteGIDs::AbstractArray{GID, 1}, remotePIDs::AbstractArray{PID, 1}
        )::Tuple{AbstractArray{GID, 1}, AbstractArray{PID, 1}
        } where {GID <: Integer, PID <: Integer, LID <: Integer}
    if length(remoteGIDs) != length(remotePIDs)
        throw(InvalidArgumentError("remote lists must be the same length"))
    end
    (exportGIDs, exportPIDs) = computeSends(dist, remoteGIDs, remotePIDs)
    createFromSends(dist, exportPIDs)

    exportGIDs, exportPIDs
end

function resolvePosts(dist::MPIDistributor{GID, PID, LID}, exportObjs::AbstractArray{T, 1}) where {T, GID<:Integer, PID<:Integer, LID<:Integer}
    myProc = myPid(dist.comm)

    dist.datatype = T

    nBlocks::GID = dist.numSends + dist.selfMsg
    procIndex::GID = 1
    while procIndex <= nBlocks && dist.procs_to[procIndex] < myProc
        procIndex += 1
    end
    if procIndex == nBlocks
        procIndex = 1
    end

    exportBytes = Vector{Vector{UInt8}}(undef, dist.numRecvs + dist.selfMsg)

    j::GID = 1

    if length(dist.indices_to) == 0 #data already grouped by processor
        for i = 1:nBlocks
            # note that the range needs to be signed ints because Julia doesn't treat unsigened ints as first class
            exportBytes[i] = arraytobytes(view(exportObjs, Int64(j):Int64(j+dist.lengths_to[i]-1)))
            j += dist.lengths_to[i]
        end
    else #data not grouped by proc, must be grouped first
        for i = 1:nBlocks
            j = dist.starts_to[i]
            sendArray = Array{T}(undef, dist.lengths_to[i])
            for k = 1:dist.lengths_to[i]
                sendArray[k] = exportObjs[dist.indices_to[j+k-1]]
            end
            exportBytes[i] = arraytobytes(sendArray)
        end
    end


    ## get sizes of data begin received ##
    lengthRequests = Vector{MPI.Request}(undef, dist.numRecvs)
    lengths = Vector{Vector{Int}}(undef, dist.numRecvs + dist.selfMsg)
    for i = 1:dist.numRecvs + dist.selfMsg
        lengths[i] = Vector{Int}(undef, 1)
    end

    j = 1

    for i = 1:dist.numRecvs + dist.selfMsg
        if dist.procs_from[i] != myProc
            lengthRequests[j] = MPI.Irecv!(lengths[i], dist.procs_from[i]-1, MPI.ANY_TAG, dist.comm.mpiComm)
            j += 1
        end
    end

    barrier(dist.comm)

    for i = 1:dist.numSends + dist.selfMsg
        p = procIndex + 1
        if p > nBlocks
            p -= nBlocks
        end
        if dist.procs_to[i] != myProc
            MPI_Rsend(length(exportBytes[i]), dist.procs_to[i]-1, 2, dist.comm.mpiComm)
        else
            lengths[i][1] = length(exportBytes[i])
        end
    end

    MPI.Waitall!(lengthRequests)
    #at this point `lengths` should contain the sizes of incoming data

    importObjs = Vector{Vector{UInt8}}(undef, dist.numRecvs+dist.selfMsg)
    for i = 1:length(importObjs)
        importObjs[i] = Vector{UInt8}(undef, lengths[i][1])
    end

    dist.importObjs = importObjs

    ## back to the regularly scheduled program ##

    k::GID = 0
    j = 0
    selfRecvAddress::GID = 0
    for i = 1:dist.numRecvs + dist.selfMsg
        if dist.procs_from[i] != myProc
            MPI.Irecv!(importObjs[i], dist.procs_from[i]-1, MPI.ANY_TAG, dist.comm.mpiComm)
        else
            selfRecvAddress = i
        end
    end

    barrier(dist.comm)

    #line 844

    selfNum::GID = 0

#    if dist.indices_to == [] #data already grouped by processor
    for i = 1:nBlocks
        p = i + procIndex - 1
        if p > nBlocks
            p -= nBlocks
        end
        if dist.procs_to[p] != myProc
            MPI_Rsend(exportBytes[p], dist.procs_to[p]-1, 3, dist.comm.mpiComm)
        else
            selfNum = p
        end
    end

    if dist.selfMsg != 0
        importObjs[selfRecvAddress] = exportBytes[selfNum]
    end

    nothing
end



function resolveWaits(dist::MPIDistributor)::Array
    barrier(dist.comm)#run into issues deserializing otherwise
    if dist.numRecvs> 0
        dist.status = MPI.Waitall!(dist.request)
    end

    if dist.importObjs == nothing
        throw(InvalidStateError("Cannot resolve waits when no posts have been made"))
    end

    T = dist.datatype
    barrier(dist.comm)#run into issues deserializing otherwise
    importObjs = dist.importObjs::Vector{Vector{UInt8}}
    deserializedObjs = Vector{Vector{T}}(undef, length(importObjs))
    for i = 1:length(importObjs)
        deserializedObjs[i] = bytestoarray(importObjs[i], T)
    end
    results = deserializedObjs

    dist.importObjs = nothing

    reduce(vcat, results; init = T[])
end


function resolveReversePosts(dist::MPIDistributor{GID, PID, LID},
        exportObjs::AbstractVector{T}
        ) where {GID <: Integer, PID <: Integer, LID <: Integer, T}
    if dist.indices_to != []
        throw(InvalidStateError("Cannot do reverse comm when data is not blocked by processor"))
    end

    if dist.planReverse == nothing
        createReverseDistributor(dist)
    end

    resolvePosts(dist.planReverse, exportObjs)
end


function resolveReverseWaits(dist::MPIDistributor{GID, PID, LID}
    )::Vector where {GID <: Integer, PID <: Integer, LID <: Integer}
    if dist.planReverse == nothing
        throw(InvalidStateError("Cannot resolve reverse waits if there is no reverse plan"))
    end

    resolveWaits(dist.planReverse)
end
