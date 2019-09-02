export getProfileType, getColMap
export resumeFill, fillComplete
export insertLocalIndices, insertGlobalIndices

#### RowGraph methods ####

getRowMap(graph::CSRGraph) = graph.rowMap
getColMap(graph::CSRGraph) = graph.colMap
getDomainMap(graph::CSRGraph) = graph.domainMap
getRangeMap(graph::CSRGraph) = graph.rangeMap
getImporter(graph::CSRGraph) = graph.importer
getExporter(graph::CSRGraph) = graph.exporter

getGlobalNumRows(graph::CSRGraph) = numGlobalElements(getRowMap(graph))
getGlobalNumCols(graph::CSRGraph) = numGlobalElements(getColMap(graph))
getLocalNumRows(graph::CSRGraph) = numMyElements(getRowMap(graph))
getLocalNumCols(graph::CSRGraph) = numMyElements(getColMap(graph))

getGlobalNumEntries(graph::CSRGraph) = graph.globalNumEntries
getLocalNumEntries(graph::CSRGraph) = graph.nodeNumEntries

Base.@propagate_inbounds function getNumEntriesInGlobalRow(graph::CSRGraph{GID}, globalRow::Integer)::Integer where {GID <: Integer}
    localRow = lid(graph.rowMap, GID(globalRow))
    getNumEntriesInLocalRow(graph, localRow)
end

function getNumEntriesInLocalRow(graph::CSRGraph{GID, PID, LID}, localRow::Integer)::Integer where {GID, PID, LID <: Integer}
    @boundscheck if !hasRowInfo(graph)
        error("Row info is gone, cannot determine number of local entries in the local row $localRow")
    end
    @boundscheck if !myLID(graph.rowMap, LID(localRow))
        error("Row $localRow is not present in this graph")
    end
    info = getRowInfo(graph, LID(localRow))
    retVal = info.numEntries
    recycleRowInfo(info)
    retVal
end

getGlobalNumDiags(graph::CSRGraph) = graph.globalNumDiags
getLocalNumDiags(graph::CSRGraph) = graph.nodeNumDiags

getGlobalMaxNumRowEntries(graph::CSRGraph) = graph.globalMaxNumRowEntries
getLocalMaxNumRowEntries(graph::CSRGraph) = graph.nodeMaxNumRowEntries

hasColMap(graph::CSRGraph) = graph.colMap != nothing

isLowerTriangular(graph::CSRGraph) = graph.lowerTriangle
isUpperTriangular(graph::CSRGraph) = graph.upperTriangle

isGloballyIndexed(graph::CSRGraph) = graph.indicesType == GLOBAL_INDICES
isLocallyIndexed(graph::CSRGraph) = graph.indicesType == LOCAL_INDICES

isFillComplete(g::CSRGraph) = g.fillComplete

function getGlobalRowCopy!(copy::AbstractVector{<:Integer}, graph::CSRGraph{GID}, globalRow::GID) where GID

    rowInfo = getRowInfoFromGlobalRow(myGraph, GID(globalRow))
    viewRange = 1:rowInfo.numEntries

    @boundscheck if rowInfo.localRow == 0
        recycleRowInfo(rowInfo)
        return LID(0)
    end

    numElts = rowInfo.numEntries

    @inbounds if isGloballyIndexed(graph)
        indsView = getGlobalView(myGraph, rowInfo[viewRange])
        for i in LID(1):numElts
            copy[i] = indsView[i]
        end
    else
        colMap = getColMap(myGraph)
        indsView = getLocalView(myGraph, rowInfo)[viewRange]
        for i in LID(1):numElts
            copy[i] = gid(colMap, indsView[i])
        end
    end

    recycleRowInfo(rowInfo)
    numElts
end


function getLocalRowCopy!(copy::AbstractVector{<:Integer},
        graph::CSRGraph{GID, PID, LID}, localRow::LID)::LID where {GID, PID, LID}

    rowInfo = getRowInfo(graph, LID(localRow))
    viewRange = 1:rowInfo.numEntries

    @boundscheck if rowInfo.localRow == 0
        recycleRowInfo(rowInfo)
        return LID(0)
    end

    numElts = rowInfo.numEntries

    @inbounds if isLocallyIndexed(graph)
        indsView = getLocalView(graph, rowInfo[viewRange])
        for i in LID(1):numElts
            copy[i] = indsView[i]
        end
    else
        colMap = getColMap(graph)
        indsView = getGlobalView(graph, rowInfo)[viewRange]

        for i in LID(1):numElts
            copy[i] = lid(colMap, indsView[i])
        end
    end

    recycleRowInfo(rowInfo)
    numElts
end


#### DistObject methods ####
function checkSizes(source::RowGraph{GID, PID, LID},
        target::CSRGraph{GID, PID, LID}) where {GID, PID, LID}
    #T and E petra's don't do any checks
    true
end

function copyAndPermute(source::RowGraph{GID, PID, LID},
        target::CSRGraph{GID, PID, LID}, numSameIDs::LID,
        permuteToLIDs::AbstractArray{LID, 1}, permuteFromLIDs::AbstractArray{LID, 1}) where {
        GID, PID, LID}
    copyAndPermuteNoViewMode(source, target,
        numSameIDs, permuteToLIDs, permuteFromLIDs)
end

function copyAndPermute(source::CSRGraph{GID, PID, LID},
        target::CSRGraph{GID, PID, LID}, numSameIDs::LID,
        permuteToLIDs::AbstractArray{LID, 1}, permuteFromLIDs::AbstractArray{LID, 1}) where {
        GID, PID, LID}
    if isFillComplete(target)
        throw(InvalidStateError("Target cannot be fill complete"))
    end
    if isFillComplete(source)
            copyAndPermuteNoViewMode(source, target,
        numSameIDs, permuteToLIDs, permuteFromLIDs)
    else
        if length(permuteToLIDs) != length(permuteFromLIDs)
            throw(InvalidArgumentError("permuteToLIDs and "
                    * "permuteFromLIDs must have the same size"))
        end

        srcRowMap = getRowMap(source)
        tgtRowMap = getRowMap(target)

        #copy part
        for myid = 1:numSameIDs
            myGID = gid(srcRowMap, myid)
            row = getGlobalRowView(source, myGID)
            insertGlobalIndices(target, myGID, row)
        end

        #permute part
        for i = 1:length(permuteToLIDs)
            srcGID = gid(srcRowMap, permuteFromLIDs[i])
            tgtGID = gid(tgtRowMap, permuteToLIDs[i])
            row = getGlobalRowView(source, srcGID)
            insertGlobalIndices(target, tgtGID, row)
        end
    end
end


function copyAndPermuteNoViewMode(source::RowGraph{GID, PID, LID},
        target::CSRGraph{GID, PID, LID}, numSameIDs::LID,
        permuteToLIDs::AbstractArray{LID, 1}, permuteFromLIDs::AbstractArray{LID, 1}) where {
        GID, PID, LID}
    if length(permuteToLIDs) != length(premuteFromLIDs)
        throw(InvalidArgumentError("permuteToLIDs and "
                * "permuteFromLIDs must have the same size"))
    end

    srcRowMap = getRowMap(source)
    tgtRowMap = getRowMap(target)

    #copy part
    for myid = 1:numSameIDs
        myGID = gid(srcRowMap, myid)
        rowCopy = getGlobalRowCopy(sourceRowGraph, myGID)
        insertGlobalIndices(target, myGID, rowCopy)
    end

    #permute part
    for i = 1:length(permuteToLIDs)
        tgtGID = gid(tgtRowMap, permuteToLIDs[i])
        srcGID = gid(srcRowMap, permuteFromLIDs[i])
        rowCopy = getGlobalRowCopy(source, srcGID)
        insertGlobalIndices(target, tgtGID, rowCopy)
    end
end



function packAndPrepare(source::RowGraph{GID, PID, LID},
        target::CSRGraph{GID, PID, LID}, exportLIDs::AbstractArray{LID, 1},
        distor::Distributor{GID, PID, LID})::Array{GID, 1} where {
        GID, PID, LID}

    pack(source, exportLIDs, distor)
end

function unpackAndCombine(target::CSRGraph{GID, PID, LID},
        importLIDs::AbstractArray{LID, 1}, imports::AbstractArray,
        distor::Distributor{GID, PID, LID}, cm::CombineMode) where {
        GID, PID, LID}
    #should be caught else where
    @assert(isFillActive(target),
        "Import and Export operations require a fill active graph")

    tgtMap = getMap(target)

    for i = 1:length(importLIDs)
        row = imports[i]
        insertGlobalIndicesFiltered(target, gid(tgtMap, importLIDs[i]), row)
    end
end



#### CSRGraph methods ####
#TODO document the CSRGraph methods

"""
    insertLocalIndices(::CSRGraph{GID, PID, LID}, localRow::Integer, [numEntries::Integer,] inds::AbstractArray{<: Integer, 1})

Inserts the given local indices into the graph.  If `numEntries` is given,
only the first `numEntries` elements are inserted
"""
function insertLocalIndices(graph::CSRGraph{GID, PID, LID}, localRow::Integer,
        numEntries::Integer, inds::AbstractArray{<:Integer, 1}) where {GID, PID, LID <: Integer}
    insertLocalIndices(graph, LID(localRow), LID(numEntries), Array{LID, 1}(inds))
end
function insertLocalIndices(graph::CSRGraph{GID, PID, LID}, localRow::LID,
        numEntries::LID, inds::AbstractArray{LID, 1}) where {
        GID, PID, LID <: Integer}
    indicesView = view(inds, 1:numEntries)
    insertLocalIndices(graph, localRow, indsT)
end

function insertLocalIndices(graph::CSRGraph{GID, PID, LID}, localRow::Integer,
        inds::AbstractArray{<:Integer, 1}) where {GID, PID, LID <: Integer}
    insertLocalIndices(graph, LID(localRow), Array{LID, 1}(inds))
end
function insertLocalIndices(graph::CSRGraph{GID, PID, LID},
        localRow::LID, indices::AbstractArray{LID, 1}) where{
        GID, PID, LID <: Integer}
    if !isFillActive(graph)
        throw(InvalidStateError("insertLocalIndices requires that fill is active"))
    end
    if isGloballyIndexed(graph)
        throw(InvalidStateError("graph indices are global, use insertGlobalIndices(...) instead"))
    end
    if !hasColMap(graph)
        throw(InvalidStateError("Cannot insert local indices without a column map"))
    end
    if !myLID(getMap(graph), localRow)
        throw(InvalidArgumentError("Row does not belong to this process"))
    end
    if !hasRowInfo(graph)
        throw(InvalidStateError("Row information was deleted"))
    end

#    colMap = getColMap(graph)
#    badColIndices = [ind for ind in indices if myLID(colMap, ind)]
#    if length(badColIndices) != 0
#        throw(InvalidArgumentError(
#            "Attempting to insert entries in owned row $localRow, "
#            * "at the following column indices: $indices.\n"
#
#            * "Of those, the following indices are not in "
#            * "the column map on this process: $badColIndices.\n"
#
#            * "Since the graph has a column map already, it is "
#            * "invalid to insert entries at those locations"))
#    end

    insertLocalIndicesImpl(graph, localRow, indices)
end


"""
    insertGlobalIndices(::CSRGraph{GID, PID, LID}, localRow::Integer, [numEntries::Integer,] inds::AbstractArray{<: Integer, 1})

Inserts the given global indices into the graph.  If `numEntries` is given,
only the first `numEntries` elements are inserted
"""
function insertGlobalIndices(graph::CSRGraph{GID, PID, LID}, globalRow::Integer,
        numEntries::Integer, inds::AbstractArray{<: Integer, 1}) where {
        GID <: Integer, PID, LID <: Integer}
    insertGlobalIndices(graph, GID(globalRow), LID(numEntries), Array{GID, 1}(inds))
end
function insertGlobalIndices(graph::CSRGraph{GID, PID, LID}, globalRow::GID,
        numEntries::LID, inds::AbstractArray{GID, 1}) where {
        GID <: Integer, PID, LID <: Integer}
    indicesView = view(inds, 1:numEntries)
    insertGlobalIndices(graph, globalRow, indsT)
end
function insertGlobalIndices(graph::CSRGraph{GID, PID, LID}, globalRow::Integer,
        inds::AbstractArray{<: Integer, 1}) where {GID <: Integer, PID, LID <: Integer}
    insertGlobalIndices(graph, GID(globalRow), Array{GID, 1}(inds))
end
function insertGlobalIndices(graph::CSRGraph{GID, PID, LID}, globalRow::GID,
        indices::AbstractArray{GID, 1}) where {GID <: Integer, PID, LID <: Integer}
    if isLocallyIndexed(graph)
        throw(InvalidStateError("Graph indices are local, use insertLocalIndices()"))
    end
    if !hasRowInfo(graph)
        throw(InvalidStateError("Graph row information was deleted"))
    end
    if isFillComplete(graph)
        throw(InvalidStateError("Cannot call this method if the fill is not active"))
    end

    myRow = lid(graph.rowMap, globalRow)
    if myRow != 0
        if false #for debuggin
            if hasColMap(graph)
                colMap = graph.colMap

                badColInds = [index for index in indices
                                    if myGid(colMap, index)==0]
                if length(badColInds) != 0
                    throw(InvalidArgumentError("$(myPid(getComm(graph))): "
                        * "Attempted to insert entries in owned row $globalRow, "
                        * "at the following column indices: $indices.\n"

                        * "Of those, the following indices are not in the "
                        * "column Map on this process: $badColInds.\n"

                        * "Since the matrix has a column map already, it "
                        * "is invalid to insert entries at those locations"))
               end
           end
        end
        insertGlobalIndicesImpl(graph, myRow, indices)
    else
        append!(graph.nonlocalRow, indices)
    end
end

"""
    insertGlobalIndicesFiltered(::CSRGraph{GID, PID, LID}, localRow::Integer, inds::AbstractArray{<: Integer, 1})

As `insertGlobalIndices(...)` but filters by those present in
the column map, if present
"""
function insertGlobalIndicesFiltered(graph::CSRGraph{GID, PID, LID}, globalRow::GID,
        indices::AbstractArray{GID, 1}) where{GID, PID, LID}
    if isLocallyIndexed(graph)
        throw(InvalidStateError(
                "graph indices are local, use insertLocalIndices(...)"))
    end
    if !hasRowInfo(graph)
        throw(InvalidStateError("Graph row information was deleted"))
    end
    if isFillComplete(graph)
        throw(InvalidStateError("Cannot insert into fill complete graph"))
    end

    myRow = lid(graph.rowMap, globalRow)
    if myRow != 0
        #if column map present, use it to filter the entries
        if hasColMap(graph)
            colMap = getColMap(graph)
            indices = [index for index in indices if myLid(colMap, index)]
        end
        insertGlobalIndicesImpl(myRow, indices)
    else
        #nonlocal row
        append!(graph.nonlocals[globalRow], indices)
    end
end

function getGlobalView(graph::CSRGraph{GID, PID, LID}, rowInfo::RowInfo{LID}) where {GID <: Integer, PID, LID <: Integer}
    if rowInfo.allocSize > 0
        if length(graph.globalIndices1D) != 0
            range = rowInfo.offset1D : rowInfo.offset1D + rowInfo.allocSize
            view(graph.globalIndices1D, range)
        elseif length(graph.globalIndices2D[rowInfo.localRow]) == 0
            globalIndices2D[rowInfo.localRow]
        else
            GID[]
        end
    else
        GID[]
    end
end

@inline function getGlobalViewPtr(graph::CSRGraph{GID, PID, LID}, rowInfo::RowInfo{LID})::Tuple{Ptr{GID}, LID} where {GID <: Integer, PID, LID <: Integer}
    if rowInfo.allocSize > 0
        if length(graph.globalIndices1D) != 0
            return (pointer(graph.globalIndices1D, rowInfo.offset1D), rowInfo.allocSize)
        elseif length(graph.globalIndices2D[rowInfo.localRow]) != 0
            baseArray = graph.globalIndices2D[rowInfo.localRow]::Vector{GID}
            return (pointer(baseArray), GID(length(baseArray)))
        end
    end
    return (Ptr{GID}(C_NULL), 0)
end

function getLocalView(graph::CSRGraph{GID, PID, LID}, rowInfo::RowInfo{LID}) where {GID <: Integer, PID, LID <: Integer}
    if rowInfo.allocSize > 0
        if length(graph.localIndices1D) != 0
            range = rowInfo.offset1D : rowInfo.offset1D + rowInfo.allocSize-LID(1)
            return view(graph.localIndices1D, range)
        elseif length(graph.localIndices2D[rowInfo.localRow]) != 0
            baseArray = graph.localIndices2D[rowInfo.localRow]
            return view(baseArray, LID(1):LID(length(baseArray)))
        end
    end
    return LID
end


Base.@propagate_inbounds @inline function getLocalViewPtr(graph::CSRGraph{GID, PID, LID}, rowInfo::RowInfo{LID})::Tuple{Ptr{LID}, LID} where {GID <: Integer, PID, LID <: Integer}
    if rowInfo.allocSize > 0
        if length(graph.localIndices1D) != 0
            return (pointer(graph.localIndices1D, rowInfo.offset1D), rowInfo.allocSize)
        elseif length(graph.localIndices2D[rowInfo.localRow]) != 0
            baseArray::Array{LID, 1} = graph.localIndices2D[rowInfo.localRow]
            return (pointer(baseArray), LID(length(baseArray)))
        end
    end
    return (C_NULL, 0)
end

function getGlobalRowView(graph::CSRGraph{GID}, globalRow::GID)::AbstractArray{GID, 1} where {GID <: Integer}
    if isLocallyIndexed(graph)
        throw(InvalidArgumentError("The graph's indices are currently stored as local indices, so a view with global column indices cannot be returned.  Use getGlobalRowCopy(::CSRGraph) instead"))
    end

    rowInfo = getRowInfoFromGlobalRow(graph, globalRow)

    if rowInfo.localRow != 0 && rowInfo.numEntries > 0
        retVal = view(getGlobalView(graph, rowInfo), 1:rowInfo.numEntries)
    else
        retVal = GID[]
    end
    recycleRowInfo(rowInfo)
    retVal
end

Base.@propagate_inbounds function getGlobalRowViewPtr(graph::CSRGraph{GID, PID, LID}, globalRow::GID)::Tuple{Ptr{GID}, LID} where {GID <: Integer, PID <: Integer, LID <: Integer}
    if isLocallyIndexed(graph)
        throw(InvalidArgumentError("The graph's indices are currently stored as local indices, so a view with global column indices cannot be returned.  Use getGlobalRowCopy(::CSRGraph) instead"))
    end

    rowInfo = getRowInfoFromGlobalRow(graph, globalRow)

    isLocalRow = true
    @boundscheck isLocalRow = rowInfo.localRow != 0

    if isLocalRow && rowInfo.numEntries > 0
        retVal = (getGlobalViewPtr(graph, rowInfo)[1], rowInfo.numEntries)
    else
        retVal = (Ptr{GID}(C_NULL), LID(0))
    end
    recycleRowInfo(rowInfo)
    retVal
end

function getLocalRowView(graph::CSRGraph{GID}, localRow::GID)::AbstractArray{GID, 1} where {GID}
    rowInfo = getRowInfoFromLocalRowIndex(graph, localRow)

    retVal = getLocalRowView(graph, rowInfo)
    recycleRowInfo(rowInfo)
    retVal
end

function getLocalRowView(graph::CSRGraph{GID, PID, LID}, rowInfo::RowInfo{LID}
        )::AbstractArray{GID, 1} where {GID, PID, LID}

    if isGloballyIndexed(graph)
        throw(InvalidArgumentError("The graph's indices are currently stored as global indices, so a view with local column indices cannot be returned.  Use getLocalRowCopy(::CSRGraph) instead"))
    end

    if rowInfo.localRow != 0 && rowInfo.numEntries > 0
        view(getLocalView(graph, rowInfo), 1:rowInfo.numEntries)
    else
        LID[]
    end
end

resumeFill(graph::CSRGraph; plist...) = resumeFill(graph, Dict(plist))

function resumeFill(graph::CSRGraph, plist::Dict)
    if !hasRowInfo(graph)
        throw(InvalidStateError("Cannot resume fill of the CSRGraph, "
                * "since the graph's row information was deleted."))
    end

    clearGlobalConstants(graph)
    graph.plist = plist
    graph.lowerTriangle = false
    graph.upperTriangle = false
    graph.indicesAreSorted = true
    graph.noRedundancies = true
    graph.fillComplete = false
end


fillComplete(graph::CSRGraph; plist...) = fillComplete(graph, Dict(plist))

function fillComplete(graph::CSRGraph, plist::Dict)
    if graph.domainMap == nothing
        domMap = graph.rowMap
    else
        domMap = graph.domainMap
    end

    if graph.rangeMap == nothing
        ranMap = graph.colMap
    else
        ranMap = graph.rangeMap
    end

    fillComplete(graph, ranMap, domMap, plist)
end

function fillComplete(graph::CSRGraph{GID, PID, LID},
        domainMap::BlockMap{GID, PID, LID}, rangeMap::BlockMap{GID, PID, LID};
        plist...) where {GID, PID, LID}
    fillComplete(graph, Dict(plist))
end

function fillComplete(graph::CSRGraph{GID, PID, LID}, domainMap::BlockMap{GID, PID, LID}, rangeMap::BlockMap{GID, PID, LID}, plist::Dict) where {GID, PID, LID}
    if !isFillActive(graph) || isFillComplete(graph)
        throw(InvalidStateError("Graph fill state must be active to call fillComplete(...)"))
    end

    numProcs = numProc(getComm(graph))

    assertNoNonlocalInserts = get(plist, :noNonlocalChanges, false)

    mayNeedGlobalAssemble = !assertNoNonlocalInserts && numProcs > 1
    if mayNeedGlobalAssemble
        globalAssemble(graph)
    else
        if numProcs == 1 && length(graph.nonLocals) > 0
            throw(InvalidStateError("Only one process, but nonlocal entries are present"))
        end
    end

    setDomainRangeMaps(graph, domainMap, rangeMap)

    if !hasColMap(graph)
        makeColMap(graph)
    end

    makeIndicesLocal(graph)

    sortAndMergeAllIndices(graph, isSorted(graph), isMerged(graph))

    makeImportExport(graph)
    computeGlobalConstants(graph)
    fillLocalGraph(graph, plist)
    graph.fillComplete(true)

    checkInternalState(graph)
end

function makeColMap(graph::CSRGraph{GID, PID, LID}) where {GID, PID, LID}
    localNumRows = getLocalNumEntries(graph)

    #TODO look at FIXME on line 4898

    error, colMap = __makeColMap(graph, graph.domainMap)

    comm = getComm(graph)
    globalError = maxAll(comm, error)

    if globalError
        Base.error("makeColMap reports an error on at least one process")
    end

    graph.colMap = colMap

    checkInternalState(graph)
end

"""
    isSorted(::CSRGraph)

Whether the indices are sorted
"""
isSorted(graph::CSRGraph) = graph.indicesAreSorted

"""
    isMerged(::CSRGraph)

Whether duplicate column indices in each row have been merged
"""
isMerged(graph::CSRGraph) = graph.noRedundancies

"""
    setAllIndices(graph::CSRGraph{GID, PID, LID}, rowPointers::Array{LID, 1}, columnIndices::AbstractArray{LID, 1})

Sets the graph's data directly, using 1D storage
"""
function setAllIndices(graph::CSRGraph{GID, PID, LID},
        rowPointers::AbstractArray{LID, 1},columnIndices::Array{LID, 1}) where {
        GID, PID, LID <: Integer}

    localNumRows = getLocalNumRows(graph)

    if graph.colMap == nothing
        throw(InvalidStateError("The graph must have a "
                * "column map before calling setAllIndices"))
    end
    if length(rowPointers) != localNumRows + 1
        throw(InvalidArgumentError("length(rowPointers) = $(length(rowPointers)) "
                * "!= localNumRows+1 = $(localNumRows+1)"))
    end

    localNumEntries = rowPointers[localNumRows+1]

    graph.indicesType    = LOCAL_INDICES
    graph.pftype         = STATIC_PROFILE
    graph.localIndices1D = columnIndices
    graph.rowOffsets     = rowPointers
    graph.nodeNumEntries = localNumEntries
    graph.storageStatus  = STORAGE_1D_UNPACKED

    graph.localGraph     = LocalCSRGraph(columnIndices, rowPointers)

    checkInternalState(graph)
end


"""
    isStorageOptimized(::CSRGraph)

Whether the graph's storage is optimized
"""
function isStorageOptimized(graph::CSRGraph)
    length(graph.numRowEntries) == 0 && getLocalNumRows(graph) > 0
end

"""
    getProfileType(::CSRGraph)

Gets the profile type of the graph
"""
getProfileType(graph::CSRGraph) = graph.pftype
