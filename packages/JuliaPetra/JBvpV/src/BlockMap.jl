export BlockMap
export remoteIDList, lid, gid
export minAllGID, maxAllGID, minMyGID, maxMyGID, minLID, maxLID
export numGlobalElements, myGlobalElements
export uniqueGIDs, globalIndicesType, sameBlockMapDataAs, sameAs
export linearMap, myGlobalElementIDs
export myGID, myLID, distributedGlobal, numMyElements


# methods and docs based straight off Epetra_BlockMap to match Comm

# ignoring indexBase methods and sticking with 1-based indexing
# ignoring elementSize methods since, type information is carried anyways
# ignoring point-related code, since elementSize is ignored


# TODO figure out expert users and developers only functions

"""
A type for partitioning block element vectors and matrices
"""
struct BlockMap{GID <: Integer, PID <:Integer, LID <: Integer}
    data::BlockMapData{GID, PID, LID}

    function BlockMap{GID, PID, LID}(data::BlockMapData) where {GID <: Integer, PID <:Integer, LID <: Integer}
        new(data)
    end
end


"""
    BlockMap(numGlobalElements, comm)

Constructor for petra-defined uniform linear distribution of elements
"""
function BlockMap(numGlobalElements::Integer, comm::Comm{GID, PID, LID}) where GID <: Integer where PID <: Integer where LID <: Integer
    BlockMap(GID(numGlobalElements), comm)
end

function BlockMap(numGlobalElements::GID, comm::Comm{GID, PID, LID}) where GID <: Integer where PID <: Integer where LID <: Integer
    if numGlobalElements < 0
        throw(InvalidArgumentError("NumGlobalElements = $(numGlobalElements).  Should be >= 0"))
    end

    data = BlockMapData(numGlobalElements, comm)
    map = BlockMap{GID, PID, LID}(data)

    numProcVal = numProc(comm)
    data.linearMap = true

    myPIDVal = myPid(comm) - 1

    data.numMyElements = floor(typeof(data.numGlobalElements),
        data.numGlobalElements/numProcVal)
    remainder = data.numGlobalElements % numProcVal
    startIndex = myPIDVal * (data.numMyElements+1)

    if myPIDVal < remainder
        data.numMyElements += 1
    else
        startIndex -= (myPIDVal - remainder)
    end

    data.minAllGID = 1
    data.maxAllGID = data.minAllGID + data.numGlobalElements - 1
    data.minMyGID = startIndex + 1
    data.maxMyGID = data.minMyGID + data.numMyElements - 1
    data.distributedGlobal = isDistributedGlobal(map, data.numGlobalElements,
        data.numMyElements)

    EndOfConstructorOps(map)
    map
end

"""
    BlockMap(numGlobalElements, numMyElements, comm)

Constructor for user-defined linear distribution of elements
"""
function BlockMap(numGlobalElements::Integer, numMyElements::Integer, comm::Comm{GID, PID, LID}) where GID <: Integer where PID <: Integer where LID <: Integer
    BlockMap(GID(numGlobalElements), LID(numMyElements), comm)
end

function BlockMap(numGlobalElements::GID, numMyElements::LID, comm::Comm{GID, PID, LID}) where GID <: Integer where PID <: Integer where LID <: Integer
    if numGlobalElements < -1
        throw(InvalidArgumentError("NumGlobalElements = $(numGlobalElements).  Should be >= -1"))
    end
    if numMyElements < 0
        throw(InvalidArgumentError("NumMyElements = $(numMyElements). Should be >= 0"))
    end

    data = BlockMapData(numGlobalElements, comm)
    map = BlockMap{GID, PID, LID}(data)

    data.numMyElements = numMyElements
    data.linearMap = true

    data.distributedGlobal = isDistributedGlobal(map, numGlobalElements, numMyElements)

    #Local Map and uniprocessor case: Each processor gets a complete copy of all elements
    if !data.distributedGlobal || numProc(comm) == 1
        data.numGlobalElements = data.numMyElements

        data.minAllGID = 1
        data.maxAllGID = data.minAllGID + data.numGlobalElements - 1
        data.minMyGID = 1
        data.maxMyGID = data.minMyGID + data.numMyElements - 1
    else
        tmp_numMyElements = data.numMyElements
        data.numGlobalElements = sumAll(data.comm, tmp_numMyElements)

        data.minAllGID = 1
        data.maxAllGID = data.minAllGID + data.numGlobalElements - 1

        tmp_numMyElements = data.numMyElements
        data.maxMyGID = scanSum(data.comm, tmp_numMyElements)

        startIndex = data.maxMyGID - data.numMyElements
        data.minMyGID = startIndex + 1
        data.maxMyGID = data.minMyGID + data.numMyElements - 1
    end
    checkValidNGE(map, numGlobalElements)

    EndOfConstructorOps(map)
    map
end


"""
    BlockMap(numGlobalElements, myGlobalElements, comm)

Constructor for user-defined arbitrary distribution of elements
"""
function BlockMap(numGlobalElements::Integer, myGlobalElements::AbstractArray{<:Integer}, comm::Comm{GID, PID,LID}
        ) where GID <: Integer where PID <: Integer where LID <: Integer
    BlockMap(numGlobalElements, Array{GID}(myGlobalElements), comm)
end

function BlockMap(numGlobalElements::Integer, myGlobalElements::UnitRange{GID}, comm::Comm{GID, PID, LID}
        ) where {GID <: Integer, PID <: Integer, LID <: Integer}

    numMyElements = LID(length(myGlobalElements))

    data = BlockMapData(GID(0), comm)
    map = BlockMap{GID, PID, LID}(data)

    data.numMyElements = numMyElements

    data.myGlobalElements = collect(myGlobalElements)
    data.minMyGID = first(myGlobalElements)
    data.maxMyGID = last(myGlobalElements)

    #TODO this doesn't check if there is overlap between processors
    # call the reduce to allow mixing this version with the abstract version
    data.linearMap = Bool(minAll(data.comm, 1))

    if numProc(comm) == 1
        data.numGlobalElements = data.numMyElements
        data.minAllGID = data.minMyGID
        data.maxAllGID = data.maxMyGID
    else
        tmp_send = [
            -((data.numMyElements > 0) ?
                data.minMyGID : Inf)
            , data.maxMyGID]

        tmp_recv = maxAll(data.comm, tmp_send)

        @assert typeof(tmp_recv[1]) <: Integer "Result type is $(typeof(tmp_recv[1])), should be subtype of Integer"

        data.minAllGID = -tmp_recv[1]
        data.maxAllGID =  tmp_recv[2]

        if numGlobalElements != -1
            data.numGlobalElements = numGlobalElements
        else
            if data.linearMap
                data.numGlobalElements = sumAll(data.comm, data.numMyElements)
            else
                #if 1+ GIDs shared between processors, need to total that correctly
                allIDs = gatherAll(data.comm, myGlobalElements)

                indexModifier = 1 - data.minAllGID
                maxGID = data.maxAllGID

                count = 0
                arr = falses(maxGID + indexModifier)
                for id in allIDs
                    if !arr[GID(id + indexModifier)]
                        arr[GID(id + indexModifier)] = true
                        count += 1
                    end
                end
                data.numGlobalElements = count
            end
        end
    end

    data.distributedGlobal = isDistributedGlobal(map, data.numGlobalElements, numMyElements)

    EndOfConstructorOps(map)
    map
end

function BlockMap(numGlobalElements::Integer, myGlobalElements::AbstractArray{GID}, comm::Comm{GID, PID,LID}
        ) where GID <: Integer where PID <: Integer where LID <: Integer
    numMyElements = LID(length(myGlobalElements))

    data = BlockMapData(GID(0), comm)
    map = BlockMap{GID, PID, LID}(data)

    data.numMyElements = numMyElements

    linear = 1
    if numMyElements > 0
        data.myGlobalElements = Array{GID, 1}(undef, numMyElements)

        data.myGlobalElements[1] = myGlobalElements[1]
        data.minMyGID = myGlobalElements[1]
        data.maxMyGID = myGlobalElements[1]

        for i = 2:numMyElements
            data.myGlobalElements[i] = myGlobalElements[i]
            data.minMyGID = min(data.minMyGID, myGlobalElements[i])
            data.maxMyGID = max(data.maxMyGID, myGlobalElements[i])

            if myGlobalElements[i] != myGlobalElements[i-1] + 1
                linear = 0
            end
        end
    else
        data.minMyGID = 1
        data.maxMyGID = 0
    end

    #TODO this doesn't check if there is overlap between processors
    data.linearMap = Bool(minAll(data.comm, linear))

    if numProc(comm) == 1
        data.numGlobalElements = data.numMyElements
        data.minAllGID = data.minMyGID
        data.maxAllGID = data.maxMyGID
    else
        tmp_send = [
            -((data.numMyElements > 0) ?
                data.minMyGID : Inf)
            , data.maxMyGID]

        tmp_recv = maxAll(data.comm, tmp_send)

        @assert typeof(tmp_recv[1]) <: Integer "Result type is $(typeof(tmp_recv[1])), should be subtype of Integer"

        data.minAllGID = -tmp_recv[1]
        data.maxAllGID =  tmp_recv[2]

        if numGlobalElements != -1
            data.numGlobalElements = numGlobalElements
        else
            if data.linearMap
                data.numGlobalElements = sumAll(data.comm, data.numMyElements)
            else
                #if 1+ GIDs shared between processors, need to total that correctly
                allIDs = gatherAll(data.comm, myGlobalElements)

                indexModifier = 1 - data.minAllGID
                maxGID = data.maxAllGID

                count = 0
                arr = falses(maxGID + indexModifier)
                for id in allIDs
                    if !arr[GID(id + indexModifier)]
                        arr[GID(id + indexModifier)] = true
                        count += 1
                    end
                end
                data.numGlobalElements = count
            end
        end
    end

    data.distributedGlobal = isDistributedGlobal(map, data.numGlobalElements, numMyElements)

    EndOfConstructorOps(map)
    map
end

"""
    BlockMap(numGlobalElements, numMyElements, myGlobalElements, isDistributedGlobal, minAllGID, maxAllGID, comm)

Constructor for user-defined arbitrary distribution of elements with all information on globals provided by the user
"""
function BlockMap(numGlobalElements::Integer, numMyElements::Integer,
        myGlobalElements::AbstractArray{GID}, userIsDistributedGlobal::Bool,
        userMinAllGID::Integer, userMaxAllGID::Integer, comm::Comm{GID, PID, LID}) where GID <: Integer where PID <: Integer where LID <: Integer
    BlockMap(GID(numGlobalElements), LID(numMyElements), Array{GID}(myGlobalElements), userIsDistributedGlobal,
        GID(userMinAllGID), GID(userMaxAllGID), comm)
end

function BlockMap(numGlobalElements::GID, numMyElements::LID,
        myGlobalElements::AbstractArray{GID}, userIsDistributedGlobal::Bool,
        userMinAllGID::GID, userMaxAllGID::GID, comm::Comm{GID, PID, LID}) where GID <: Integer where PID <: Integer where LID <: Integer
    if numGlobalElements < -1
        throw(InvalidArgumentError("NumGlobalElements = $(numGlobalElements).  Should be >= -1"))
    end
    if numMyElements < 0
        throw(InvalidArgumentError("NumMyElements = $(numMyElements). Should be >= 0"))
    end
    if userMinAllGID < 1
        throw(InvalidArgumentError("Minimum global element index = $(data.minAllGID).  Should be >= 1"))
    end

    data = BlockMapData(numGlobalElements, comm)
    map = BlockMap{GID, PID, LID}(data)

    data.numMyElements = numMyElements

    linear = 1
    if numMyElements > 0
        data.myGlobalElements = Vector{GID}(undef, numMyElements)

        data.myGlobalElements[1] = myGlobalElements[1]
        data.minMyGID = myGlobalElements[1]
        data.maxMyGID = myGlobalElements[1]

        for i = 2:numMyElements
            data.myGlobalElements[i] = myGlobalElements[i]
            data.minMyGID = min(data.minMyGID, myGlobalElements[i])
            data.maxMyGID = max(data.maxMyGID, myGlobalElements[i])

            if myGlobalElements[i] != myGlobalElements[i-1] + 1
                linear = 0
            end
        end

    else
        data.minMyGID = 1
        data.maxMyGID = 0
    end

    data.linearMap = Bool(minAll(comm, linear))

    data.distributedGlobal = userIsDistributedGlobal

     if !data.distributedGlobal || numProc(comm) == 1
        data.numGlobalElements = data.numMyElements
        checkValidNGE(map, numGlobalElements)
        data.minAllGID = data.minMyGID
        data.maxAllGID = data.maxMyGID
    else
        if numGlobalElements == -1
            data.numGlobalElements = sumAll(data.comm, data.numMyElements)
        else
            data.numGlobalElements = numGlobalElements
        end
        checkValidNGE(data.numGlobalELements)

        data.minAllGID = userMinAllGID
        data.maxAllGID = userMaxAllGID
    end
    EndOfConstructorOps(map)
    map
end



##### internal construction methods #####
function isDistributedGlobal(map::BlockMap{GID, PID, LID}, numGlobalElements::GID,
        numMyElements::LID) where GID <: Integer where PID <: Integer where LID <: Integer
    data = map.data
    if numProc(data.comm) > 1
        localReplicated = numGlobalElements == numMyElements
        !Bool(minAll(data.comm, localReplicated))
    else
        false
    end
end

function EndOfConstructorOps(map::BlockMap)
    map.data.minLID = 1
    map.data.maxLID = max(map.data.numMyElements, 1)

    GlobalToLocalSetup(map);
end

function GlobalToLocalSetup(map::BlockMap)
    data = map.data
    numMyElements = data.numMyElements
    myGlobalElements = data.myGlobalElements

    if data.linearMap || numMyElements == 0
        return map
    end
    if length(data.numGlobalElements) == 0
        return map
    end


    val = myGlobalElements[1]
    i = 1
    while i < numMyElements
        if val+1 != myGlobalElements[i+1]
            break
        end
        val += 1
    end

    data.lastContiguousGIDLoc = i
    if data.lastContiguousGIDLoc <= 1
        data.lastContiguousGID = myGlobalElements[1]
    else
        data.lastContiguousGID = myGlobalElements[data.lastContiguousGIDLoc]
    end

    if i < numMyElements
        data.lidHash = empty!(data.lidHash)

        sizehint!(data.lidHash, numMyElements - i + 2)

        for i = i:numMyElements
            data.lidHash[myGlobalElements[i]] = i
        end
    end
    map
end

function checkValidNGE(map::BlockMap{GID, PID, LID}, numGlobalElements::GID) where GID <: Integer where PID <: Integer where LID <: Integer
    if (numGlobalElements != -1) && (numGlobalElements != map.data.numGlobalElements)
        throw(InvalidArgumentError("Invalid NumGlobalElements.  "
              * "NumGlobalElements = $(numGlobalElements)"
              * ".  Should equal $(map.data.numGlobalElements)"
              * ", or be set to -1 to compute automatically"))
    end
end

##### external methods #####

getComm(map::BlockMap) = map.data.comm

"""
    myGID(map::BlockMap, gidVal::Integer)

Return true if the GID passed in belongs to the calling processor in this
map, otherwise returns false.
"""
myGID(map::BlockMap, gidVal) = lid(map, gidVal) != 0

"""
    myLID(map::BlockMap, lidVal::Integer)

Return true if the LID passed in belongs to the calling processor in this
map, otherwise returns false.
"""
@inline myLID(map::BlockMap, lidVal) = gid(map, lidVal) != 0

"""
    distributedGlobal(map::BlockMap)

Return true if map is defined across more than one processor
"""
distributedGlobal(map::BlockMap) = map.data.distributedGlobal

"""
    numMyElements(map::BlockMap{GID, PID, LID})::LID

Return the number of elements across the calling processor
"""
numMyElements(map::BlockMap) = map.data.numMyElements

"""
    minMyGID(map::BlockMap{GID, PID, LID})::GID

Return the minimum global ID owned by this processor
"""
minMyGID(map::BlockMap) = map.data.minMyGID

"""
    maxMyGID(map::BlockMap{GID, PID, LID})::GID

Return the maximum global ID owned by this processor
"""
maxMyGID(map::BlockMap) = map.data.maxMyGID

"""
    getLocalMap(::BlockMap{GID, PID, LID})::BlockMap{GID, PID, LID}

Creates a copy of the given map that doesn't support any inter-process actions
"""
function getLocalMap(map::BlockMap{GID, PID, LID})::BlockMap{GID, PID, LID} where {GID, PID, LID}
    oldData = map.data
    data = BlockMapData(oldData.numGlobalElements, LocalComm(oldData.comm))

    data.directory = nothing
    data.lid = copy(oldData.lid)
    #maps shouldn't be modified anyways, may as well share array
    #data.myGlobalElements =  copy(oldData.myGlobalElements)
    data.myGlobalElements = oldData.myGlobalElements
    data.numMyElements = oldData.numMyElements
    data.minAllGID = oldData.minAllGID
    data.maxAllGID = oldData.maxAllGID
    data.minMyGID = oldData.minMyGID
    data.maxMyGID = oldData.maxMyGID
    data.minLID = oldData.minLID
    data.maxLID = oldData.maxLID
    data.linearMap = oldData.linearMap
    data.distributedGlobal = oldData.distributedGlobal
    data.oneToOneIsDetermined = oldData.oneToOneIsDetermined
    data.oneToOne = oldData.oneToOne
    data.lastContiguousGID = oldData.lastContiguousGID
    data.lastContiguousGIDLoc = oldData.lastContiguousGIDLoc
    data.lidHash = copy(oldData.lidHash)

    BlockMap{GID, PID, LID}(data)
end

##local/global ID accessor methods##

"""
    remoteIDList(map::BlockMap{GID, PID, LID}, gidList::AbstractArray{<: Integer}::Tuple{AbstractArray{PID}, AbstractArray{LID}}

Return the processor ID and local index value for a given list of global indices.
The returned value is a tuple containing
1. an Array of processors owning the global ID's in question
2. an Array of local IDs of the global on the owning processor
"""
function remoteIDList(map::BlockMap{GID, PID, LID}, gidList::AbstractArray{<:Integer}
        )::Tuple{AbstractArray{PID}, AbstractArray{LID}} where GID <: Integer where PID <: Integer where LID <: Integer
    remoteIDList(map, Vector{GID}(gidList))
end

function remoteIDList(map::BlockMap{GID, PID, LID}, gidList::AbstractArray{GID}
        )::Tuple{AbstractArray{PID}, AbstractArray{LID}} where GID <: Integer where PID <: Integer where LID <: Integer
    data = map.data
    if data.directory == nothing
        data.directory = createDirectory(data.comm, map)
    end

    getDirectoryEntries(data.directory, map, gidList)
end


"""
    lid(map::BlockMap{GID, PID, LID}, gid::Integer)::LID

Return local ID of global ID, or 0 if not found on this processor
"""
@inline function lid(map::BlockMap{GID, PID, LID}, gid::Integer) where GID <: Integer where PID <: Integer where LID <: Integer
    data = map.data
    if (gid < data.minMyGID) || (gid > data.maxMyGID)
         LID(0)
    elseif data.linearMap
        LID(gid - data.minMyGID + 1)
    elseif gid >= data.myGlobalElements[1] && gid <= data.lastContiguousGID
        LID(gid - data.myGlobalElements[1] + 1)
    elseif haskey(data.lidHash, GID(gid))
        data.lidHash[gid]
    else
        LID(0)
    end
end

"""
    gid(map::BlockMap{GID, PID, LID}, lid::Integer)::GID

Return global ID of local ID, or 0 if not found on this processor
"""
@inline function gid(map::BlockMap{GID, PID, LID}, lid::Integer) where GID <: Integer where PID <: Integer where LID <: Integer
    data = map.data
    if (data.numMyElements == LID(0)) || (lid < data.minLID) || (lid > data.maxLID)
        GID(0)
    elseif data.linearMap
        GID(lid + data.minMyGID - 1)
    else
        GID(data.myGlobalElements[lid])
    end
end


"""
    minAllGID(map::BlockMap{GID, PID, LID})::GID

Return the minimum global ID across the entire map
"""
minAllGID(map::BlockMap) = map.data.minAllGID

"""
    maxAllGID(map::BlockMap{GID, PID, LID})::GID

Return the maximum global ID across the entire map
"""
maxAllGID(map::BlockMap) = map.data.maxAllGID

"""
    minLID(map::BlockMap{GID, PID, LID})::LID

Return the mimimum local index value on the calling processor
"""
minLID(map::BlockMap) = map.data.minLID

"""
    maxLID(map::BlockMap{GID, PID, LID})::LID

Return the maximum local index value on the calling processor
"""
maxLID(map::BlockMap) = map.data.maxLID

##size/dimension accessor functions##

"""
    numGlobalElements(map::BlockMap{GID, PID, LID})::GID

Return the number of elements across all processors
"""
numGlobalElements(map::BlockMap) = map.data.numGlobalElements

"""
    myGlobalElements(map::BlockMap{GID, PID, LID})::AbstractArray{GID}

Return a list of global elements on this processor
"""
function myGlobalElements(map::BlockMap{GID})::AbstractArray{GID} where GID <: Integer
    data = map.data

    if length(data.myGlobalElements) == 0
        myGlobalElements = Vector{GID}(undef, data.numMyElements)
        @inbounds for i = GID(1):GID(data.numMyElements)
            myGlobalElements[i] = data.minMyGID + i - 1
        end
        data.myGlobalElements = myGlobalElements
    else
        data.myGlobalElements
    end
end


##Miscellaneous boolean tests##

"""
    uniqueGIDs(map::BlockMap)::Bool

Return true if each map GID exists on at most 1 processor
"""
uniqueGIDs(map::BlockMap) = isOneToOne(map)


"""
    globalIndicesType(map::BlockMap{GID, PID, LID})::Type{GID}

Return the type used for global indices in the map
"""
globalIndicesType(map::BlockMap{GID}) where GID <: Integer = GID

"""
    sameBlockMapDataAs(this::BlockMap, other::BlockMap)::Bool

Return true if the maps have the same data
"""
sameBlockMapDataAs(this::BlockMap, other::BlockMap) = this.data == other.data

"""
    sameAs(this::BlockMap, other::BlockMap)::Bool

Return true if this and other are identical maps
"""
sameAs(this::BlockMap, other::BlockMap) = false
# behavior by specification

function sameAs(this::BlockMap{GID, PID, LID}, other::BlockMap{GID, PID, LID})::Bool where GID <: Integer where PID <: Integer where LID <: Integer
    tData = this.data
    oData = other.data
    if tData == oData
        return true
    end

    if ((tData.minAllGID != oData.minAllGID)
        || (tData.maxAllGID != oData.maxAllGID)
        || (tData.numGlobalElements != oData.numGlobalElements))
        return false
    end

    mySameMap = 1

    if tData.numMyElements != oData.numMyElements
        mySameMap = 0
    end

    if tData.linearMap && oData.linearMap
        # For linear maps, just need to check whether lower bound is the same
        if tData.minMyGID != oData.minMyGID
            mySameMap = 0
        end
    else
        for i = 1:tData.numMyElements
            if gid(this, i) != gid(other, i)
                mySameMap = 0
                break
            end
        end
    end

    Bool(minAll(tData.comm, mySameMap))
end


"""
    linearMap(map::BlockMap)::Bool

Return true if the global ID space is contiguously divided (but
not necessarily uniformly) across all processors
"""
linearMap(map::BlockMap) = map.data.linearMap


##Array accessor functions##

"""
    myGlobalElementsIDs map::BlockMap{GID, PID, LID})::AbstractArray{GID}

Return list of global IDs assigned to the calling processor
"""
function myGlobalElementIDs(map::BlockMap{GID})::AbstractArray{GID} where GID <: Integer
    data = map.data
    if length(data.myGlobalElements) == 0
        base = 0:data.numMyElements-1
        rng = data.minMyGID .+ base
        collect(rng)
    else
        copy(data.myGlobalElements)
    end
end


function isOneToOne(map::BlockMap)::Bool
    data = map.data
    if !(data.oneToOneIsDetermined)
        data.oneToOne = determineIsOneToOne(map)
        data.oneToOneIsDetermined = true
    end
    data.oneToOne
end

function determineIsOneToOne(map::BlockMap)::Bool
    data = map.data
    if numProc(data.comm) < 2
        true
    else
        if data.directory == nothing
            data.directory = createDirectory(data.comm, map)
        end
       gidsAllUniquelyOwned(data.directory)
    end
end
