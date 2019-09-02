export BasicDirectory

"""
    BasicDirectory(map::BlockMap)
Creates a BasicDirectory, which implements the methods of Directory with
basic implmentations
"""
mutable struct BasicDirectory{GID <: Integer, PID <:Integer, LID <: Integer} <: Directory{GID, PID, LID}
    map::BlockMap{GID, PID, LID}

    directoryMap::Union{BlockMap, Nothing}

    procList::Vector{PID}
    procListLists::Vector{Vector{PID}}

    entryOnMultipleProcs::Bool

    localIndexList::Vector{LID}
    allMinGIDs::Vector{GID}

    function BasicDirectory{GID, PID, LID}(map::BlockMap{GID, PID, LID}) where {GID, PID, LID}

        if !(distributedGlobal(map))
            new(map, nothing, [], [], numProc(getComm(map))!=1, [], [])
        elseif linearMap(map)
            commObj = getComm(map)

            allMinGIDs = gatherAll(commObj, minMyGID(map))
            allMinGIDs = vcat(allMinGIDs, [1+maxAllGID(map)])

            entryOnMultipleProcs = length(Set(allMinGIDs)) != length(allMinGIDs)

            new(map, nothing, [], [], entryOnMultipleProcs, [], allMinGIDs)
        else
            generateContent(
                new(map, nothing, [], [], false, [], []),
                map)
        end
    end
end

"""
internal method to assist constructor
"""
function generateContent(dir::BasicDirectory{GID, PID, LID}, map::BlockMap{GID, PID, LID}) where GID <: Integer where PID <: Integer where LID <: Integer
    minAllGID = minAllGID(map)
    maxAllGID = maxAllGID(map)

    dirNumGlobalElements = maxAllGID - minAllGID + 1

    directoryMap = BlockMap(dirNumGlobalElements, minAllGID, commObj)
    dir.directoryMap = directoryMap

    dirNumMyElements = numMyElements(dir.directoryMap)

    if dirNumMyElements > 0
        dir.procList = Vector{PID}(undef, dirNumMyElements)
        dir.localIndexList = Vector{LID}(undef, dirNumMyElements)

        fill!(dir.procList, -1)
        fill!(dir.localIndexList, -1)
    else
        dir.procList = []
        dir.localIndexList = []
    end

    map_numMyElements = numMyElements(map)
    map_myGlobalElements = myGlobalElements(map)

    sendProcs = remoteIDList(directoryMap, map_numMyElements, myGlobalElements(map))

    distributor = createDistributor(commObj)
    numRecvs = createFromSends(distributor, map_numMyElements, sendProcs)

    exportElements = Array{Tuple{GID, PID, LID}}(numMyElements)

    myPIDVal = myPID(commObj)
    for i = 1:numMyElements
        exportElements[i] = (map_myGlobalElements[i], myPIDVal, i)
    end

    importElements = resolve(distributor, exportElements)


    for i = 1:numRecvs
        currLID = lid(directoryMap, importElements[i][1])
        @assert currLID > 0 //internal error

        proc = importElements[i][2]
        if dir.procList[currLID] >= 0
            if dir.procList[currLID] != proc
                if dir.procListLists == []
                    numProcLists = numMyElements(directoryMap)
                    procListLists = Vector{Vector{PID}}(undef, numProcLists)
                    fill!(procListLists, PID[])
                end

                l = procListLists[currLID]

                index = searchsortedfirst(l, procList[currLID])
                insert(l, index, procList[currLID])

                index = searchsortedfirst(l, proc)
                insert(l, index, proc)

                dir.procList[currLID] = dir.procListLists[curr_LID][1]
            end
        else
            dir.procList[currLID] = proc
        end

        dir.localIndexList[currLID] = importElements[i][3]
    end

    globalVal = maxAll(commObj, numProcLists)
    dir.entryOnMultipleProcs = globalval > 0 ? true : false;

    dir
end


function getDirectoryEntries(directory::BasicDirectory{GID, PID, LID}, map::BlockMap{GID, PID, LID}, globalEntries::AbstractVector{GID},
        high_rank_sharing_procs::Bool)::Tuple{Vector{PID}, Vector{LID}} where GID <: Integer where PID <: Integer where LID <: Integer
    numEntries = length(globalEntries)
    procs = Vector{PID}(undef, numEntries)
    localEntries = Vector{LID}(undef, numEntries)

    if !distributedGlobal(map)
        myPIDVal = myPid(getComm(map))

        for i = 1:numEntries
            lidVal = lid(map, globalEntries[i])

            if lidVal == 0
                procs[i] = 0
                warn("GID $(globalEntries[i]) is not part of this map")
            else
                procs[i] = myPIDVal
            end
            localEntries[i] = lidVal
        end
    elseif linearMap(map)
        minAllGIDVal = minAllGID(map)
        maxAllGIDVal = maxAllGID(map)

        numProcVal = numProc(getComm(map))

        n_over_p = numGlobalElements(map)/numProcVal

        allMinGIDs_list = copy(directory.allMinGIDs)
        order = sortperm(allMinGIDs_list)
        permute!(allMinGIDs_list, order)

        for i = 1:numEntries
            lid  = 0
            proc = 0

            gid = globalEntries[i]
            if gid < minAllGIDVal || gid > maxAllGIDVal
                throw(InvalidArgumentError("GID=$gid out of valid range [$minAllGIDVal, $maxAllGIDVal]"))
            end
            #guess uniform distribution and start a little above it
            proc1 = min(GID(fld(gid, max(n_over_p, 1)) + 2), numProcVal)
            proc1 = 1
            found = false

            while proc1 >= 1 && proc1 <= numProcVal
                if allMinGIDs_list[proc1] <= gid
                    if (gid < allMinGIDs_list[proc1+1])
                        found = true
                        break
                    else
                        proc1 += 1
                    end
                else
                    proc1 -= 1
                end
            end
            if found
                proc = order[proc1]
                lid = gid - allMinGIDs_list[proc1] + 1
            end

            procs[i] = proc
            localEntries[i] = lid
        end
    else #general case
        distributor = createDistributor(getComm(map))

        dirProcs = remoteIDList(map, numEntries, globalEntries)

        numMissing = 0
        for i = 1:numEntries
            if dirProcs[i] == 0
                procs[i] = 0
                localEntries[i] = 0
                numMissing += 1
            end
        end

        (sendGIDs, sendPIDs) = createFromRecvs(distrbutor, globalEntries, dirProcs)
        numSends = length(sendGIDs)

        if numSends > 0
            exports = Array{Tuple{GID, PID, LID}}(numSends)
            for i = 1:numSends
                currGID = sendGIDs[i]
                exports[i][1] = currGID

                currLID = lid(map, currGID)
                @assert currLID > 0 #internal error
                if !high_rank_sharing_procs
                    exports[i][2] = procList[currLID]
                else
                    numProcLists = numMyElements(directory.directoryMap)
                    if numProcLists > 0
                        num = length(directory.procListLists[currLID])
                        if num > 1
                            exports[i][2] = directory.procListLists[currLID][num]
                        else
                            exports[i][2] = directory.procList[currLID]
                        end
                    else
                        exports[i][2] = directory.procList[currLID]
                    end
                end
                exports[i][3] = directory.localIndexList[currLID]
            end
        end

        numRecv = numEntries - numMissing
        imports = resolve(distributor, exports)

        offsets = sortperm(globalEntries)
        sortedGE = globalEntries[offsets]

        for i = 1:numRecv
            currLID = imports[i][1]
            j = searchsortedfirst(sortedGE, currLID)
            if j > 0
                procs[offsets[j]] = imports[i][2]
                localEntries[offsets[j]] = imports[i][3]
            end
        end
    end
    (procs, localEntries)
end

function gidsAllUniquelyOwned(directory::BasicDirectory)
    !directory.entryOnMultipleProcs
end
