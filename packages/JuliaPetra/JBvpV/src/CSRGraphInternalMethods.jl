

#DECISION put this somewhere else?  Its only an internal grouping
mutable struct RowInfo{LID <: Integer}
    graph::CSRGraph{<:Integer, <:Integer, LID}
    localRow::LID
    allocSize::LID
    numEntries::LID
    offset1D::LID
end

#RowInfo object for re-use
const rowInfoSpare = Union{RowInfo, Nothing}[nothing]

"""
    Gets a `RowInfo` object with the given values, reusing an intance if able
"""
@inline function createRowInfo(graph::CSRGraph{<:Integer, <:Integer, LID}, localRow::LID,
        allocSize::LID, numEntries::LID, offset1D::LID)::RowInfo{LID} where {LID <: Integer}
    global rowInfoSpare

    @inbounds begin#if length(rowInfoSpare) > 0
        #rowInfoSpare should always be size 1
        nextVal = rowInfoSpare[1]
        #ensure object pool haves right type
        if nextVal isa RowInfo{LID}
            rowInfoSpare[1] = nothing

            rowInfo::RowInfo{LID} = nextVal
            rowInfo.graph = graph
            rowInfo.localRow = localRow
            rowInfo.allocSize = allocSize
            rowInfo.numEntries = numEntries
            rowInfo.offset1D = offset1D
            return rowInfo
        end
    end
    #couldn't reuse, create new instance
    return RowInfo{LID}(graph, localRow, allocSize, numEntries, offset1D)
end

"""
    Puts the `RowInfo` object back in the object pool.
    After calling this method remove all references to the object.
"""
@inline function recycleRowInfo(rowInfo::RowInfo{T}) where T
    @inbounds rowInfoSpare[1] = rowInfo
    nothing
end


#TODO implement getLocalDiagOffsets(::CSRGraph)
getLocalGraph(graph::CSRGraph) = graph.localGraph


function updateGlobalAllocAndValues(graph::CSRGraph{GID, PID, LID}, rowInfo::RowInfo{LID}, newAllocSize::Integer, rowValues::AbstractArray{Data, 1}) where {Data, GID, PID, LID}

    resize!(graph.globalIndices2D[rowInfo.localRow], newAllocSize)
    resize!(rowValues, newAllocSize)

    nothing
end

function insertIndicesAndValues(graph::CSRGraph{GID, PID, LID}, rowInfo::RowInfo{LID}, newInds::Union{AbstractArray{GID, 1}, AbstractArray{LID, 1}}, oldRowVals::AbstractArray{Data, 1}, newRowVals::AbstractArray{Data, 1}, lg::IndexType) where {Data, GID, PID, LID}
    numNewInds = insertIndices(graph, rowInfo, newInds, lg)
    oldInd = rowInfo.numEntries+1

    oldRowVals[range(oldInd, step=1, length=numNewInds)] = newRowVals[1:numNewInds]
end

function insertIndices(graph::CSRGraph{GID, PID, LID}, rowInfo::RowInfo{LID}, newInds::Union{AbstractArray{GID, 1}, AbstractArray{LID, 1}}, lg::IndexType) where {GID, PID, LID}
    numNewInds = LID(length(newInds))
    if lg == GLOBAL_INDICES
        if isGloballyIndexed(graph)
            numEntries = rowInfo.numEntries
            (gIndPtr, gIndLen) = getGlobalViewPtr(graph, rowInfo)
            @assert gIndLen >= numNewInds+numEntries
            for i in 1:numNewInds
                unsafe_store!(gIndPtr, GID(newInds[i]), numEntries+i)
            end
        else
            lIndView = getLocalView(graph, rowInfo)
            colMap = graph.colMap

            dest = range(rowInfo.numEntries, step=1, length=numNewInds)
            lIndView[dest] = [lid(colMap, GID(id)) for id in newInds]
        end
    elseif lg == LOCAL_INDICES
        if isLocallyIndexed(graph)
            numEntries = rowInfo.numEntries
            (lIndPtr, lIndLen) = getLocalViewPtr(graph, rowInfo)
            @assert gIndLen >= numNewInds+numEntries
            for i in 1:numNewInds
                unsafe_store!(lIndPtr, LID(newInds[i]), numEntries+i)
            end
        else
            @assert(false,"lg=LOCAL_INDICES, isGloballyIndexed(g) not implemented, "
            * "because it doesn't make sense")
        end
    end

    graph.numRowEntries[rowInfo.localRow] += numNewInds
    graph.nodeNumEntries += numNewInds
    setLocallyModified(graph)

    numNewInds
end


function computeGlobalConstants(graph::CSRGraph{GID, PID, LID}) where {
        GID <: Integer, PID <: Integer, LID <: Integer}

    #short circuit if already computed
    graph.haveGlobalConstants && return

    computeLocalConstants(graph)

    commObj = getComm(getRowMap(graph))

    #if graph.haveGlobalConstants == false  #short circuited above
    graph.globalNumEntries, graph.globalNumDiags = sumAll(commObj,
        [GID(graph.nodeNumEntries), GID(graph.nodeNumDiags)])

    graph.globalMaxNumRowEntries = maxAll(commObj, GID(graph.nodeMaxNumRowEntries))
    graph.haveGlobalConstants = true
end

function clearGlobalConstants(graph::CSRGraph)
    graph.globalNumEntries = 0
    graph.globalNumDiags = 0
    graph.globalMaxNumRowEntries = 0
    graph.haveGlobalConstants = false
end


function computeLocalConstants(graph::CSRGraph{GID, PID, LID}) where {
        GID <: Integer, PID <: Integer, LID <: Integer}

    #short circuit if already computed
    graph.haveLocalConstants && return

    #if graph.haveLocalConstants == false  #short circuited above

    graph.upperTriangle = true
    graph.lowerTriangle = true
    graph.nodeMaxNumRowEntries = 0
    graph.nodeNumDiags = 0

    rowMap = graph.rowMap
    colMap = graph.colMap

    #indicesAreAllocated => true
    if  hasRowInfo(graph)
        numLocalRows = numMyElements(rowMap)
        for localRow = LID(1):numLocalRows
            globalRow = gid(rowMap, localRow)
            rowLID = lid(colMap, globalRow)

            rowInfo = getRowInfo(graph, localRow)
            (rowPtr, rowLen) = getLocalViewPtr(graph, rowInfo)


            for i in 1:rowLen
                if unsafe_load(rowPtr) == rowLID
                    graph.nodeNumDiags += 1
                    break
                end
            end

            smallestCol::LID = unsafe_load(rowPtr, 1)
            largestCol::LID  = unsafe_load(rowPtr, rowLen)
            if smallestCol < localRow
                graph.upperTriangle = false
            end
            if localRow < largestCol
                graph.lowerTriangle = false
            end
            graph.nodeMaxNumRowEntries = max(graph.nodeMaxNumRowEntries, rowInfo.numEntries)

            recycleRowInfo(rowInfo)
        end
    end
    graph.haveLocalConstants = true
end


hasRowInfo(graph::CSRGraph) = (getProfileType(graph) != STATIC_PROFILE
                                || length(graph.rowOffsets) != 0)

Base.@propagate_inbounds function getRowInfoFromGlobalRow(graph::CSRGraph{GID, PID, LID},
        row::Integer)::RowInfo{LID} where {GID, PID, LID <: Integer}
    getRowInfo(graph, lid(graph.rowMap, row))
end

@inline function getRowInfo(graph::CSRGraph{GID, PID, LID}, row::LID)::RowInfo{LID} where {GID, PID, LID <: Integer}

    emptyRowInfo = !hasRowInfo(graph)
    @boundscheck emptyRowInfo = emptyRowInfo || !myLID(graph.rowMap, row)
    if emptyRowInfo
        return createRowInfo(graph, row, LID(0), LID(0), LID(1))
    end

    offset1D::LID = 1
    allocSize::LID = 0

    @inbounds if getProfileType(graph) == STATIC_PROFILE
        if length(graph.rowOffsets) != 0
            offset1D  = LID(graph.rowOffsets[row])
            allocSize = LID(graph.rowOffsets[row+1] - graph.rowOffsets[row])
        end
        numEntries = (length(graph.numRowEntries) == 0 ?
            allocSize : LID(graph.numRowEntries[row]))
    else #dynamic profile
        if isLocallyIndexed(graph) && length(graph.localIndices2D) != 0
            allocSize = LID(length(graph.localIndices2D[row]))

        elseif isGloballyIndexed(graph) && length(graph.globalIndices2D) != 0
            allocSize = LID(length(graph.globalIndices2D[row]))
        end
        numEntries = (length(graph.numRowEntries) == 0 ?
            LID(0) : LID(graph.numRowEntries[row]))
    end
    createRowInfo(graph, row, allocSize, numEntries, offset1D)
end

function getLocalView(rowInfo::RowInfo{LID})::AbstractArray{LID, 1} where LID <: Integer
    graph = rowInfo.graph
    if rowInfo.allocSize == 0
        LID[]
    elseif length(graph.localIndices1D) != 0
        start = rowInfo.offset1D
        len = rowInfo.allocSize

        view(graph.localIndices1D, range(start, step=1, length=len))
    elseif length(graph.localIndices2D[rowInfo.localRow]) != 0
        graph.localIndices2D[rowInfo.localRow]
    else
        LID[]
    end
end

function allocateIndices(graph::CSRGraph{GID, <:Integer, LID},
        lg::IndexType, numAllocPerRow::AbstractArray{<:Integer, 1}) where {
        GID <: Integer, LID <: Integer}
    numRows = getLocalNumRows(graph)
    @assert(length(numAllocPerRow) == numRows,
        "numAllocRows has length = $(length(numAllocPerRow)) "
        * "!= numRows = $numRows")
    allocateIndices(graph, lg, numAllocPerRow, i -> numAllocPerRow[i])
end

function allocateIndices(graph::CSRGraph{GID, <:Integer, LID},
        lg::IndexType, numAllocPerRow::Integer) where {
        GID <: Integer, LID <: Integer}

# Manually inlined since the function version is too expensive

    @assert(isLocallyIndexed(graph) == (lg == LOCAL_INDICES),
        "Graph is $(isLocallyIndexed(graph) ? "" : "not ")locally indexed, but lg=$lg")
    @assert(isGloballyIndexed(graph) == (lg == GLOBAL_INDICES),
        "Graph is $(isGloballyIndexed(graph) ? "" : "not ")globally indexed but lg=$lg")

    numRows = getLocalNumRows(graph)

    if getProfileType(graph) == STATIC_PROFILE
        rowPtrs = Array{LID, 1}(undef, numRows + 1)

        computeOffsets(rowPtrs, numAllocPerRow)

        graph.rowOffsets = rowPtrs
        numInds = rowPtrs[numRows+1]

        if lg == LOCAL_INDICES
            graph.localIndices1D = Array{LID, 1}(undef, numInds)
        else
            graph.globalIndices1D = Array{GID, 1}(undef, numInds)
        end
        graph.storageStatus = STORAGE_1D_UNPACKED
    else
        if lg == LOCAL_INDICES
            graph.localIndices2D = Array{Array{LID, 1}, 1}(undef, numRows)
            for row = 1:numRows
                graph.localIndices2D[row] = Array{LID, 1}(undef, numAllocPerRow)
            end
        else #lg == GLOBAL_INDICES
            graph.globalIndices2D = Array{Array{GID, 1}, 1}(undef, numRows)
            for row = 1:numRows
                graph.globalIndices2D[row] = Array{GID, 1}(undef, numAllocPerRow)
            end
        end
        graph.storageStatus = STORAGE_2D
    end

    graph.indicesType = lg

    if numRows > 0
        numRowEntries = zeros(LID, numRows)
        graph.numRowEntries = numRowEntries
    end
end

function allocateIndices(graph::CSRGraph{GID, <:Integer, LID},
        lg::IndexType, numAlloc, numAllocPerRow::Function) where {
        GID <: Integer, LID <: Integer}

    @assert(isLocallyIndexed(graph) == (lg == LOCAL_INDICES),
        "Graph is $(isLocallyIndexed(graph) ? "" : "not ")locally indexed, but lg=$lg")
    @assert(isGloballyIndexed(graph) == (lg == GLOBAL_INDICES),
        "Graph is $(isGloballyIndexed(graph) ? "" : "not ")globally indexed but lg=$lg")

    numRows = getLocalNumRows(graph)

    if getProfileType(graph) == STATIC_PROFILE
        rowPtrs = Array{LID, 1}(undef, numRows + 1)

        computeOffsets(rowPtrs, numAlloc)

        graph.rowOffsets = rowPtrs
        numInds = rowPtrs[numRows+1]

        if lg == LOCAL_INDICES
            graph.localIndices1D = Array{LID, 1}(undef, numInds)
        else
            graph.globalIndices1D = Array{GID, 1}(undef, numInds)
        end
        graph.storageStatus = STORAGE_1D_UNPACKED
    else
        if lg == LOCAL_INDICES
            graph.localIndices2D = Array{Array{LID, 1}, 1}(undef, numRows)
            for row = 1:numRows
                graph.localIndices2D[row] = Array{LID, 1}(undef, numAllocPerRow(row))
            end
        else #lg == GLOBAL_INDICES
            graph.globalIndices2D = Array{Array{GID, 1}, 1}(undef, numRows)
            for row = 1:numRows
                graph.globalIndices2D[row] = Array{GID, 1}(undef, numAllocPerRow(row))
            end
        end
        graph.storageStatus = STORAGE_2D
    end

    graph.indicesType = lg

    if numRows > 0
        numRowEntries = zeros(LID, numRows)
        graph.numRowEntries = numRowEntries
    end
end


function makeImportExport(graph::CSRGraph{GID, PID, LID}) where {
        GID <: Integer, PID <: Integer, LID <: Integer}
    @assert (graph.colMap != nothing) "Cannot make imports and exports without a column map"

    if graph.importer == nothing
        if !sameAs(graph.domainMap, graph.colMap)
            graph.importer = Import(graph.domainMap, graph.colMap)
        end
    end

    if graph.exporter == nothing
        if !sameAs(graph.rangeMap, graph.rowMap)
            graph.exporter = Export(graph.rowMap, graph.rangeMap)
        end
    end
end

"""
    checkInternalState(::CSRGraph)

Checks the graphs internal state for correctness.
Mainly useful for intnernal debugging and testing purposes
"""
function checkInternalState(graph::CSRGraph)
    localNumRows = getLocalNumRows(graph)

    @assert(isFillActive(graph) != isFillComplete(graph),
        "Graph must be either fill active or fill "
        * "complete$(isFillActive(graph) ? "not both" : "").")
    @assert(!isFillComplete(graph)
            || (graph.colMap != nothing
                && graph.domainMap != nothing
                && graph.rangeMap != nothing),
        "Graph is fill complete, but at least one of {column, range, domain} map is null")
    @assert((graph.storageStatus != STORAGE_1D_PACKED
                && graph.storageStatus != STORAGE_1D_UNPACKED)
        || graph.pftype != DYNAMIC_PROFILE,
        "Graph claims 1D storage, but dynamic profile")
    if graph.storageStatus == STORAGE_2D
        @assert(graph.pftype != STATIC_PROFILE ,
            "Graph claims 2D storage, but static profile")
        @assert(!isLocallyIndexed(graph)
            || length(graph.localIndices2D) == localNumRows,
            "Graph calims to be locally index and have 2D storage, "
            * "but length(graph.localIndices2D) = $(length(graph.localIndices2D)) "
            * "!= getLocalNumRows(graph) = $localNumRows")
        @assert(!isGloballyIndexed(graph)
            || length(graph.globalIndices2D) == localNumRows,
            "Graph calims to be globally index and have 2D storage, "
            * "but length(graph.globalIndices2D) = $(length(graph.globalIndices2D)) "
            * "!= getLocalNumRows(graph) = $localNumRows")
    end

    @assert(graph.haveGlobalConstants
        || (graph.globalNumEntries == 0
            && graph.globalNumDiags == 0
            && graph.globalMaxNumRowEntries == 0),
        "Graph claims to not have global constants, "
        * "but some of the global constants are not 0")

    @assert(!graph.haveGlobalConstants
        || (graph.globalNumEntries != 0
            && graph.globalMaxNumRowEntries != 0),
        "Graph claims to have global constants, but also says 0 global entries")

    @assert(!graph.haveGlobalConstants
        || (graph.globalNumEntries >= graph.nodeNumEntries
            && graph.globalNumDiags >= graph.nodeNumDiags
            && graph.globalMaxNumRowEntries >= graph.nodeMaxNumRowEntries),
        "Graph claims to have global constants, but some of the local "
        * "constants are greater than their corresponding global constants")

    @assert(!isStorageOptimized(graph)
        || graph.pftype == STATIC_PROFILE,
        "Storage is optimized, but graph is not STATIC_PROFILE")

    @assert(!isGloballyIndexed(graph)
        || length(graph.rowOffsets) == 0
        || (length(graph.rowOffsets) == localNumRows +1
            && graph.rowOffsets[localNumRows+1] == length(graph.globalIndices1D)),
        "If rowOffsets has nonzero size and the graph is globally "
        * "indexed, then rowOffsets must have N+1 rows and rowOffsets[N+1] "
        * "must equal the length of globalIndices1D")

    @assert(!isLocallyIndexed(graph)
        || length(graph.rowOffsets) == 0
        || (length(graph.rowOffsets) == localNumRows +1
            && graph.rowOffsets[localNumRows+1] == length(graph.localIndices1D)),
        "If rowOffsets has nonzero size and the graph is globally "
        * "indexed, then rowOffsets must have N+1 rows and rowOffsets[N+1] "
        * "must equal the length of localIndices1D")

    if graph.pftype == DYNAMIC_PROFILE
        @assert(localNumRows == 0
            || length(graph.localIndices2D) > 0
            || length(graph.globalIndices2D) > 0,
            "Graph has dynamic profile, the calling process has nonzero "
            * "rows, but no 2-D column index storage is present.")
        @assert(localNumRows == 0
            || length(graph.numRowEntries) != 0,
            "Graph has dynamic profiles and the calling process has "
            * "nonzero rows, but numRowEntries is not present")

        @assert(length(graph.localIndices1D) == 0
            && length(graph.globalIndices1D) == 0,
            "Graph has dynamic profile, but 1D allocations are present")

        @assert(length(graph.rowOffsets) == 0,
            "Graph has dynamic profile, but row offsets are present")

    elseif graph.pftype == STATIC_PROFILE
        @assert(length(graph.localIndices1D) != 0
            || length(graph.globalIndices1D) != 0,
            "Graph has static profile, but 1D allocations are not present")

        @assert(length(graph.localIndices2D) == 0
            && length(graph.globalIndices2D) == 0,
            "Graph has static profile, but 2D allocations are present")
    else
        error("Unknown profile type: $(graph.pftype)")
    end

    if graph.indicesType == LOCAL_INDICES
        @assert(length(graph.globalIndices1D) == 0
            && length(graph.globalIndices2D) == 0,
            "Indices are local, but global allocations are present")
        @assert(graph.nodeNumEntries == 0
            || length(graph.localIndices1D) > 0
            || length(graph.localIndices2D) > 0,
            "Indices are local and local entries exist, but there aren't local allocations present")
    elseif graph.indicesType == GLOBAL_INDICES
        @assert(length(graph.localIndices1D) == 0
            && length(graph.localIndices2D) == 0,
            "Indices are global, but local allocations are present")
        @assert(graph.nodeNumEntries == 0
            || length(graph.globalIndices1D) > 0
            || length(graph.globalIndices2D) > 0,
            "Indices are global and local entries exist, but there aren't global allocations present")
    else
        warn("Unknown indices type: $(graph.indicesType)")
    end

    #check actual allocations
    lenRowOffsets = length(graph.rowOffsets)
    if graph.pftype == STATIC_PROFILE && lenRowOffsets != 0
        @assert(lenRowOffsets == localNumRows+1,
            "Graph has static profile, rowOffsets has a nonzero length "
            * "($lenRowOffsets), but is not equal to the "
            * "local number of rows plus one ($(localNumRows+1))")
        actualNumAllocated = graph.rowOffsets[localNumRows+1]
        @assert(!isLocallyIndexed(graph)
            || length(graph.localIndices1D) == actualNumAllocated,
            "Graph has static profile, rowOffsets has a nonzero length, "
            * "but length(localIndices1D) = $(length(graph.localIndices1D)) "
            * "!= actualNumAllocated = $actualNumAllocated")
        @assert(!isGloballyIndexed(graph)
            || length(graph.globalIndices1D) == actualNumAllocated,
            "Graph has static profile, rowOffsets has a nonzero length, "
            * "but length(globalIndices1D) = $(length(graph.globalIndices1D)) "
            * "!= actualNumAllocated = $actualNumAllocated")
    end
    true #if an problem occurred, an error was already thrown
end

function setLocallyModified(graph::CSRGraph)
    graph.indicesAreSorted = false
    graph.noRedundancies = false
    graph.haveLocalConstants = false
end

function sortAndMergeAllIndices(graph::CSRGraph, sorted::Bool, merged::Bool)
    @assert(isLocallyIndexed(graph),
        "This method may only be called after makeIndicesLocal(graph)")
    @assert(merged || isStoragedOptimized(graph),
        "The graph is already storage optimized, "
        * "so we shouldn't be merging any indices.")

    if !sorted || !merged
        localNumRows = getLocalNumRows(graph)
        totalNumDups = 0
        for localRow = 1:localNumRows
            rowInfo = getRowInfo(graph, localRow)
            if !sorted
                sortRowIndices(graph, rowInfo)
            end
            if !merged
                numDups += mergeRowIndices(graph, rowInfo)
            end
            recycleRowInfo(rowInfo)
        end
        graph.nodeNumEntries -= totalNumDups
        graph.indiciesAreSorted = true
        graph.noRedunancies = true
    end
end

function sortRowIndices(graph::CSRGraph{GID, PID, LID}, rowInfo::RowInfo{LID}) where {GID, PID, LID <: Integer}
    if rowInfo.numEntries > 0
        localColumnIndices = getLocalView(graph, rowInfo)
        sort!(localColumnIndices)
    end
end

function mergeRowIndices(graph::CSRGraph{GID, PID, LID}, rowInfo::RowInfo{LID}) where {GID, PID, LID <: Integer}
    localColIndices = getLocalView(graph, rowInfo)
    localColIndices[:] = unique(localColIndices)
    mergedEntries = length(localColIndices)
    graph.numRowEntries[rowInfo.localRow] = mergedEntries

    rowInfo.numEntries - mergedEntries
end


function setDomainRangeMaps(graph::CSRGraph{GID, PID, LID}, domainMap::BlockMap{GID, PID, LID}, rangeMap::BlockMap{GID, PID, LID}) where {GID, PID, LID}
    if graph.domainMap != domainMap
        graph.domainMap = domainMap
        graph.importer = nothing
    end
    if graph.rangeMap != rangeMap
        graph.rangeMap = rangeMap
        graph.exporter = nothing
    end
end


function globalAssemble(graph::CSRGraph)
    @assert isFillActive(graph) "Fill must be active before calling globalAssemble(graph)"

    comm = getComm(graph)
    myNumNonlocalRows = length(graph.nonlocals)

    maxNonlocalRows = maxAll(comm, myNumNonlocalRows)
    if maxNonlocalRows != 0
        return
    end

    #skipping: nonlocalRowMap = null

    numEntPerNonlocalRow = Array{LID, 1}(undef, myNumNonlocalRows)
    myNonlocalGlobalRows = Array{GID, 1}(undef, myNumNonlocalRows)

    for (i, (key, val)) = zip(1:length(graph.nonlocals), graph.nonlocals)
        myNonlocalGlobalRows[i] = key
        globalCols = val
        sort!(globalCols)
        globalCols[:] = unique(globalCols)
        numEntPerNonlocalRow[i] = length(globalCols)
    end

    myMinNonLocalGlobalRow = minimum(myNonLocalGlobalRows)

    globalMinNonlocalRow = minAll(comm, myMinNonlocalGlobalRow)

    nonlocalRowMap = BlockMap(-1, myNonlocalGlobalRows, comm)

    nonlocalGraph = CSRGraph(nonlocalRowMap, numEntPerNonlocalRow, STATIC_PROFILE)
    for (i, (key, val)) = zip(1:length(graph.nonlocals), graph.nonlocals)
        globalRow = key
        globalColumns = val
        numEnt = length(numEntPerNonlocalRow[i])
        insertGlobalIndices(nonLocalGraph, globalRow, numEnt, globalColumns)
    end

    origRowMap = graph.rowMap
    origRowMapIsOneToOne = isOneToOne(origRowMap)

    if origRowMapIsOneToOne
        exportToOrig = Export(nonlocalRowMap, origRowMap)
        doExport(nonLocalGraph, graph, exportToOrig, INSERT)
    else
        oneToOneRowMap = createOneToOne(origRowMap)
        exportToOneToOne = Export(nonlocalRowMap, oneToOneRowMap)

        oneToOneGraph = CSRGraph(oneToOneRowMap, 0)
        doExport(nonlocalGraph, oneToOneGraph, exportToOneToOne, INSERT)

        #keep memory highwater mark down
        #nonlocalGraph = null

        importToOrig(oneToOneRowMap, origRowMap)
        doImport(oneToOneGraph, graph, importToOrig, INSERT)
    end
    clear!(graph.nonLocals)
end

function makeIndicesLocal(graph::CSRGraph{GID, PID, LID}) where {GID, PID, LID}
    @assert hasColMap(graph) "The graph does not have a column map yet.  This method should never be called in that case"

    colMap = graph.colMap
    localNumRows = getLocalNumRows(graph)

    if isGloballyIndexed(graph) && localNumRows != 0
        numRowEntries = graph.numRowEntries

        if getProfileType(graph) == STATIC_PROFILE
            if GID == LID
                graph.localIndices1D = graph.globalIndices1D

            else
                @assert(length(graph.rowOffsets) != 0,
                    "length(graph.rowOffsets) == 0.  "
                    * "This should never happen at this point")
                numEnt = graph.rowOffsets[localNumRows+1]
                graph.localIndices1D = Array{LID, 1}(undef, numEnt)
            end


            localColumnMap = getLocalMap(colMap)

            numBad = convertColumnIndicesFromGlobalToLocal(
                        graph.localIndices1D,
                        graph.globalIndices1D,
                        graph.rowOffsets,
                        localColumnMap,
                        numRowEntries)

            if numBad != 0
                throw(InvalidArgumentError("When converting column indices from "
                        * "global to local, we encountered $numBad indices that "
                        * "do not live in the column map on this process"))
            end

            graph.globalIndices1D = Array{LID, 1}(undef, 0)
        else #graph has dynamic profile
            graph.localIndices2D = Array{Array{LID, 1}, 1}(undef, localNumRows)
            for localRow = 1:localNumRows
                if length(graph.globalIndices2D[localRow]) != 0
                    globalIndices = graph.globalIndices2D[localRow]

                    graph.localIndices2D[localRow] = [lid(colMap, gid) for gid in globalIndices]
                end
            end
            graph.globalIndices2D = Array{GID, 1}[]
        end
    end

    graph.localGraph = LocalCSRGraph(graph.localIndices1D, graph.rowOffsets)
    graph.indicesType = LOCAL_INDICES
end


function convertColumnIndicesFromGlobalToLocal(localColumnIndices::AbstractArray{LID, 1},
        globalColumnIndices::AbstractArray{GID, 1}, ptr::AbstractArray{LID, 1},
        localColumnMap::BlockMap{GID, PID, LID}, numRowEntries::AbstractArray{LID, 1}
        )::LID where {GID, PID, LID}


    localNumRows = max(length(ptr)-1, 0)
    numBad = 0
    for localRow = 1:localNumRows
        offset = ptr[localRow]

        for j = 0:numRowEntries[localRow]-1
            gid = globalColumnIndices[offset+j]
            localColumnIndices[offset+j] = lid(localColumnMap, gid)
            if localColumnIndices[offset+j] == 0
                numBad += 1
            end
        end
    end
    numBad
end

#covers the overlap between insert methods
macro insertIndicesImpl(indicesType, innards)
    indices1D = Symbol(indicesType*"Indices1D")
    indices2D = Symbol(indicesType*"Indices2D")

    esc(quote
            rowInfo = getRowInfo(graph, myRow)
            numNewIndices = length(indices)
            newNumEntries = rowInfo.numEntries + numNewIndices

            if newNumEntries > rowInfo.allocSize
                if getProfileType(graph) == STATIC_PROFILE
                    $innards
                else
                    newAllocSize = 2*rowInfo.allocSize
                    if newAllocSize < newNumEntries
                        newAllocSize = newNumEntries
                    end
                    resize!(graph.$indices2D[myRow], newAllocSize)
                end
            end

            if length(graph.$indices1D) != 0
                offset = rowInfo.offset1D + rowInfo.numEntries
                destRange = offset+1:offset+numNewIndices

                graph.$indices1D[destRange] = indices[:]
            else
                graph.$indices2D[myRow][rowInfo.numEntries+1:newNumEntries] = indices[:]
            end

            graph.numRowEntries[myRow] += numNewIndices
            graph.nodeNumEntries += numNewIndices
            setLocallyModified(graph)

            recycleRowInfo(rowInfo)
            nothing
    end)
end

function insertLocalIndicesImpl(graph::CSRGraph{GID, PID, LID},
        myRow::LID, indices::AbstractArray{LID, 1}) where {
        GID, PID, LID <: Integer}
    @insertIndicesImpl "local" begin
        throw(InvalidArgumentError("new indices exceed statically allocated graph structure"))
    end
end

#TODO figure out if this all can be moved to @insertIndicesImpl
function insertGlobalIndicesImpl(graph::CSRGraph{GID, PID, LID},
        myRow::LID, indices::AbstractArray{GID, 1}) where {
        GID <: Integer, PID, LID <: Integer}
    @insertIndicesImpl "global" begin
        @assert(rowInfo.numEntries <= rowInfo.allocSize,
            "For local row $myRow, rowInfo.numEntries = $(rowInfo.numEntries) "
            * "> rowInfo.allocSize = $(rowInfo.allocSize).")

        dupCount = 0
        if length(graph.globalIndices1D) != 0
            curOffset = rowInfo.offset1D
            @assert(length(graph.globalIndices1D) >= curOffset,
                "length(graph.globalIndices1D) = $(length(graph.globalIndices1D)) "
                * ">= curOffset = $curOffset")
            @assert(length(graph.globalIndices1D) >= curOffset + rowInfo.offset1D,
                "length(graph.globalIndices1D) = $(length(graph.globalIndices1D)) "
                * ">= curOffset+rowInfo.offset1D = $(curOffset + rowInfo.offset1D)")

            range = curOffset:curOffset+rowInfo.numEntries
            globalIndicesCur = view(graph.globalIndices1D, range)
        else
            #line 1959

            globalIndices = graph.globalIndices2D[myRow]
            @assert(rowInfo.allocSize == length(globalIndices),
                "rowInfo.allocSize = $(rowInfo.allocSize) "
                * "== length(globalIndices) = $(length(globalIndices))")
            @assert(rowInfo.numEntries <= length(globalIndices),
                "rowInfo.numEntries = $(rowInfo.numEntries) "
                * "== length(globalIndices) = $(length(globalIndices))")

            globalIndicesCur = view(globalIndices, 0, rowInfo.numEntries)
        end
        for newIndex = indices
            dupCount += count(old -> old==newIndex, globalIndicesCur)
        end

        numNewToInsert = numNewInds - dupCount
        @assert numNewToInsert >= 0 "More duplications than indices"

        if rowInfo.numEntries + numNewToInsert > rowInfo.allocSize
            throw(InvalidArgumentError("$(myPid(getComm(graph))): "
                    * "For local row $myRow, even after excluding "
                    * "$dupCount duplicate(s) in input, the new number "
                    * "of entries $(rowInfo.numEntries + numNewToInsert) "
                    * "still exceeds this row's static allocation size "
                    * "$(rowInfo.allocSize).  You must either fix the upper "
                    * "bound on number of entries in this row, or switch "
                    * "to dynamic profile."))
        end

        if length(graph.globalIndices) != 0
            curOffset = rowInfo.offset1D
            globalIndicesCur = view(graph.globalIndices1D,
                range(curOffset, step=1, length=rowInfo.numEntries))
            globalIndicesNew = view(graph.globalIndices1D,
                curOffset+rowInfo.numEntries+1 : currOffset+rowInfo.allocSize)
        else
            #line 2036

            globalIndices = graph.globalIndices2D[myRow]
            globalIndicesCur = view(globalIndices, 1:rowInfo.numEntries)
            globalIndicesNew = view(globalIndices,
                rowInfo.numEntries+1 : rowInfo.allocSize-rowInfo.numEntries)
        end

        curPos = 1
        for globalIndexToInsert = indices

            alreadyInOld = globalIndexToInsert in globalIndicesCur
            if !alreadyInOld
                @assert(curPos <= numNewToInsert,
                    "curPos = $curPos >= numNewToInsert = $newToInsert.")
                globalIndicesNew[curPos] = globalIndexToInsert
                curPos += 1
            end
        end

        graph.numRowEntries[myRow] = rowInfo.numEntries+numNewToInsert
        graph.nodeNumEntries += numNewToInsert
        setLocallyModified(graph)
        return
    end
end



#internal implementation of makeColMap, needed to handle some return and debuging stuff
#returns Tuple(error, colMap)
function __makeColMap(graph::CSRGraph{GID, PID, LID}, domMap::Union{BlockMap{GID, PID, LID}, Nothing}
        ) where {GID, PID, LID}
    error = false

    if domMap == nothing
        return nothing
    end

    if isLocallyIndexed(graph)
        colMap = graph.colMap

        if colMap == nothing
            warn("$(myPid(getComm(graph))): The graph is locally indexed, but does not have a column map")

            error = true
            myColumns = GID[]
        else
            if linearMap(colMap) #i think isContiguous(map) <=> linearMap(map)?
                numCurGIDs = numMyElements(colMap)
                myFirstGlobalIndex = minMyGIDs(colMap)

                myColumns = collect(range(myFirstGlobalIndex, step=1, length=numCurGIDs))
            else
                myColumns = copy(myGlobalElements(colMap))
            end
        end
        return (error, BlockMap(numGlobalElements(colMap), myColumns, getComm(domMap)))
    end

    #else if graph.isGloballyIndexed
    localNumRows = getLocalNumRows(graph)

    numLocalColGIDs = 0

    gidIsLocal = falses(localNumRows)
    remoteGIDSet = Set()

    #if rowMap != null
    rowMap = graph.rowMap

    for localRow = 1:localNumRows
        globalRow = gid(rowMap, localRow)
        (rowGIDPtr, numEnt) = getGlobalRowViewPtr(graph, globalRow)

        if numEnt != 0
            for k = 1:numEnt
                gid::GID = unsafe_load(rowGIDPtr, k)
                lid::LID = JuliaPetra.lid(domMap, gid)
                if lid != 0
                    @inbounds if !gidIsLocal[lid]
                        gidIsLocal[lid] = true
                        numLocalColGIDs += 1
                    end
                else
                    #don't need containment checks, set already takes care of that
                    push!(remoteGIDSet, gid)
                end
            end
        end
    end



    numRemoteColGIDs = length(remoteGIDSet)

    #line 214, abunch of explanation of serial short circuit
    if numProc(getComm(domMap)) == 1
        if numRemoteColGIDs != 0
            error = true
        end
        if numLocalColGIDs == localNumRows
            return (error, domMap)
        end
    end
    myColumns = Vector{GID}(undef, numLocalColGIDs+numRemoteColGIDs)
    localColGIDs  = view(myColumns, 1:numLocalColGIDs)
    remoteColGIDs = view(myColumns, numLocalColGIDs+1:numLocalColGIDs+numRemoteColGIDs)

    remoteColGIDs[:] = [el for el in remoteGIDSet]

    remotePIDs = Array{PID, 1}(undef, numRemoteColGIDs)

    remotePIDs = remoteIDList(domMap, remoteColGIDs)[1]
    if any(remotePIDs .== 0)
        warn("Some column indices are not in the domain Map")
        error = true
    end

    order = sortperm(remotePIDs)
    permute!(remotePIDs, order)
    permute!(remoteColGIDs, order)

    #line 333

    numDomainElts = numMyElements(domMap)
    if numLocalColGIDs == numDomainElts
        if linearMap(domMap) #I think isContiguous() <=> linearMap()
            localColGIDs[1:numLocalColGIDs] = range(minMyGID(domMap), step=1, length=numLocalColGIDs)
        else
            domElts = myGlobalElements(domMap)
            localColGIDs[1:length(domElts)] = domElts
        end
    else
        numLocalCount = 0
        if linearMap(domMap) #I think isContiguous() <=> linearMap()
            curColMapGID = minMyGID(domMap)
            for i = 1:numDomainElts
                if gidIsLocal[i]
                    numLocalCount += 1
                    localColGIDs[numLocalCount] = curColMapGID
                end
                curColMapGID += 1
            end
        else
            domainElts = myGlobalElement(domMap)
            for i = 1:numDomainElts
                if gidIsLocal[i]
                    numLocalCount += 1
                    localColGIDs[numLocalCount] = domainElts[i]
                end
                curColMapGID += 1
            end
        end

        if numLocalCount != numLocalColGIDs
            error = true
        end
    end

    return (error, BlockMap(numGlobalElements(domMap), myColumns, getComm(domMap)))
end
