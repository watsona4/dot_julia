
export Export
export sourceMap, targetMap, distributor, isLocallyComplete
export permuteToLIDs, permuteFromLIDs, exportLIDs, remoteLIDs, remotePIDs, numSameIDs

"""
Communication plan for data rekg.ribution from a (possibly) multiple-owned to a uniquely owned distribution
"""
struct Export{GID <: Integer, PID <:Integer, LID <: Integer}
    exportData::ImportExportData{GID, PID, LID}
end

#TODO document

## Constructors ##

function Export(source::BlockMap{GID, PID, LID}, target::BlockMap{GID, PID, LID}, remotePIDs::Union{AbstractArray{PID}, Nothing}=nothing; plist...) where {GID <: Integer, PID <: Integer, LID <: Integer}
    Export(source, target,
        Dict(Tuple{Symbol, Any}[pair for pair in plist]))
end

function Export(source::BlockMap{GID, PID, LID}, target::BlockMap{GID, PID, LID},
        plist::Dict{Symbol}) where {GID <: Integer, PID <: Integer, LID <: Integer}
    Export(source, target, nothing, plist)
end

function Export(source::BlockMap{GID, PID, LID}, target::BlockMap{GID, PID, LID},
        remotePIDs::Union{AbstractArray{PID}, Nothing}, plist::Dict{Symbol}) where {
            GID <: Integer, PID <: Integer, LID <: Integer}

    expor = Export(ImportExportData(source, target))

    exportGIDs = setupSamePermuteExport(expor)

    if distributedGlobal(source)
        setupRemote(expor, exportGIDs)
    end

    expor
end


## internal construction methods ##

function setupSamePermuteExport(expor::Export{GID, PID, LID})::AbstractArray{GID} where {GID <: Integer, PID <: Integer, LID <: Integer}

    data = expor.exportData

    source = sourceMap(expor)
    target = targetMap(expor)

    sourceGIDs = myGlobalElements(source)
    targetGIDs = myGlobalElements(target)


    numSrcGIDs = length(sourceGIDs)
    numTgtGIDs = length(targetGIDs)
    numGIDs = min(numSrcGIDs, numTgtGIDs)

    numSameGIDs = 1
    while numSameGIDs <= numGIDs && sourceGIDs[numSameGIDs] == targetGIDs[numSameGIDs]
        numSameGIDs += 1
    end
    numSameGIDs -= 1
    numSameIDs(data, numSameGIDs)

    exportGIDs = Array{GID, 1}(undef, 0)
    permuteToLIDs = JuliaPetra.permuteToLIDs(data)
    permuteFromLIDs = JuliaPetra.permuteFromLIDs(data)
    exportLIDs = JuliaPetra.exportLIDs(data)

    for srcLID = (numSameGIDs+1):numSrcGIDs
        curSrcGID = sourceGIDs[srcLID]
        tgtLID = lid(target, curSrcGID)
        if tgtLID != 0
            push!(permuteToLIDs, tgtLID)
            push!(permuteFromLIDs, srcLID)
        else
            push!(exportGIDs, curSrcGID)
            push!(exportLIDs, srcLID)
        end
    end

    if length(exportLIDs) != 0 && !distributedGlobal(source)
        isLocallyComplete(data, false)
        warn("Source has export LIDs but source not distributed globally.  " *
            "Exporting to a submap of the target map.")
    end

    if distributedGlobal(source)
        #resize!(JuliaPetra.exportPIDs(data), length(exportGIDs))

        (exportPIDs, exportLIDs) = remoteIDList(target, exportGIDs)
        JuliaPetra.exportPIDs(data, exportPIDs)
        missingGIDs = 0
        for i = 1:length(exportPIDs)
            if exportPIDs[i] == 0
                missingGIDs += 1
            end
        end

        if missingGIDs != 0
            warn("The source Map has GIDs not found in the target Map")

            isLocallyComplete(data, false)
            numInvalidExports = missingGIDs
            totalNumExports = length(exportPIDs)

            if numInvalidExports == totalNumExports
                # all exports invalid, can delete all exports
                resize!(exportGIDs, 0)
                resize!(exportLIDs, 0)
                resize!(exportPIDs, 0)
            else
                #some exports are valid, need to keep the valid exports
                numValidExports = 1
                for e = 1:totalNumExports
                    if exportPIDs[e] != 0
                        exportGIDs[numValidExports] = exportGIDs[e]
                        exportLIDs[numValidExports] = exportLIDs[e]
                        exportPIDs[numValidExports] = exportPIDs[e]
                        numValidExports += 1
                    end
                end
                numValidExports -= 1

                resize!(exportGIDs, numValidExports)
                resize!(exportLIDs, numValidExports)
                resize!(exportPIDs, numValidExports)
            end
        end
    end
    exportGIDs
end

function setupRemote(expor::Export{GID, PID, LID}, exportGIDs::AbstractArray{GID, 1}) where {GID <: Integer, PID <: Integer, LID <: Integer}

    data = expor.exportData

    target = targetMap(data)

    exportPIDs = JuliaPetra.exportPIDs(data)

    order = sortperm(exportPIDs)
    permute!(exportPIDs, order)
    permute!(exportLIDs(data), order)
    permute!(exportGIDs, order)

    numRemoteIDs = createFromSends(distributor(data), exportPIDs)

    remoteGIDs = resolve(distributor(data), exportGIDs)

    remoteLIDs = JuliaPetra.remoteLIDs(data)

    resize!(remoteLIDs, numRemoteIDs)

    for i in 1:length(remoteGIDs)
        remoteLIDs[i] = lid(target, remoteGIDs[i])
    end

end
## Getters ##

"""
Get the source map for the given ImportExportData
"""
function sourceMap(impor::Export{GID, PID, LID})::BlockMap{GID, PID, LID} where GID <: Integer where PID <:Integer where LID <: Integer
    impor.exportData.source
end

"""
Get the target map for the given ImportExportData
"""
function targetMap(impor::Export{GID, PID, LID})::BlockMap{GID, PID, LID} where GID <: Integer where PID <:Integer where LID <: Integer
    impor.exportData.target
end

"""
List of elements in the target map that are permuted.
"""
function permuteToLIDs(impor::Export{GID, PID, LID})::Array{LID} where GID <: Integer where PID <:Integer where LID <: Integer
    impor.exportData.permuteToLIDs
end

"""
List of elements in the source map that are permuted.
"""
function permuteFromLIDs(impor::Export{GID, PID, LID})::Array{LID} where GID <: Integer where PID <:Integer where LID <: Integer
    impor.exportData.permuteFromLIDs
end

"""
List of elements in the target map that are coming from other processors
"""
function remoteLIDs(impor::Export{GID, PID, LID})::Array{LID} where GID <: Integer where PID <: Integer where LID <: Integer
    impor.exportData.remoteLIDs
end

"""
List of elements that will be sent to other processors
"""
function exportLIDs(impor::Export{GID, PID, LID})::Array{LID} where GID <: Integer where PID <: Integer where LID <: Integer
    impor.exportData.exportLIDs
end

"""
List of processors to which elements will be sent `exportLID[i]` will be sent to processor `exportPIDs[i]`
"""
function exportPIDs(impor::Export{GID, PID, LID})::Array{PID} where GID <: Integer where PID <: Integer where LID <: Integer
    impor.exportData.exportPIDs
end

"""
Returns the number of elements that are identical between the source and target maps, up to the first different ID
"""
function numSameIDs(impor::Export{GID, PID, LID})::LID where GID <: Integer where PID <: Integer where LID <: Integer
    impor.exportData.numSameIDs
end


"""
Returns the distributor being used
"""
function distributor(impor::Export{GID, PID, LID})::Distributor{GID, PID, LID} where GID <: Integer where PID <: Integer where LID <: Integer
    impor.exportData.distributor
end

"""
Returns whether the import or export is locally complete
"""
function isLocallyComplete(impor::Export{GID, PID, LID})::Bool where GID <: Integer where PID <: Integer where LID <: Integer
    impor.exportData.isLocallyComplete
end
