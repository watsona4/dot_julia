mutable struct ImportExportData{GID <: Integer, PID <: Integer, LID <: Integer}
    source::BlockMap{GID, PID, LID}
    target::BlockMap{GID, PID, LID}

    permuteToLIDs::Array{LID, 1}
    permuteFromLIDs::Array{LID, 1}
    remoteLIDs::Array{LID, 1}

    exportLIDs::Array{LID, 1}
    exportPIDs::Array{PID, 1}

    numSameIDs::GID
    distributor::Distributor{GID, PID, LID}

    isLocallyComplete::Bool
end

## Constructors ##
function ImportExportData(source::BlockMap{GID, PID, LID}, target::BlockMap{GID, PID, LID})::ImportExportData{GID, PID, LID} where GID <: Integer where PID <:Integer where LID <: Integer
    ImportExportData{GID, PID, LID}(source, target, [], [], [], [], [], 0, createDistributor(getComm(source)), true)
end


## Getters ##
function sourceMap(data::ImportExportData{GID, PID, LID})::BlockMap{GID, PID, LID} where GID <: Integer where PID <:Integer where LID <: Integer
    data.source
end

function targetMap(data::ImportExportData{GID, PID, LID})::BlockMap{GID, PID, LID} where GID <: Integer where PID <:Integer where LID <: Integer
    data.target
end

function permuteToLIDs(data::ImportExportData{GID, PID, LID})::Array{LID} where GID <: Integer where PID <:Integer where LID <: Integer
    data.permuteToLIDs
end

function permuteFromLIDs(data::ImportExportData{GID, PID, LID})::Array{LID} where GID <: Integer where PID <:Integer where LID <: Integer
    data.permuteFromLIDs
end

function remoteLIDs(data::ImportExportData{GID, PID, LID})::Array{LID} where GID <: Integer where PID <: Integer where LID <: Integer
    data.remoteLIDs
end

function remoteLIDs(data::ImportExportData{GID, PID, LID}, remoteLIDs::AbstractArray{<: Integer}) where GID <: Integer where PID <: Integer where LID <: Integer
    data.remoteLIDs = remoteLIDs
end

function exportLIDs(data::ImportExportData{GID, PID, LID})::Array{LID} where GID <: Integer where PID <: Integer where LID <: Integer
    data.exportLIDs
end

function exportLIDs(data::ImportExportData{GID, PID, LID}, exportLIDs::AbstractArray{<: Integer}) where GID <: Integer where PID <: Integer where LID <: Integer
    data.exportLIDs = exportLIDs
end

function exportPIDs(data::ImportExportData{GID, PID, LID})::Array{PID} where GID <: Integer where PID <: Integer where LID <: Integer
    data.exportPIDs
end

function exportPIDs(data::ImportExportData{GID, PID, LID}, exportPIDs::AbstractArray{<: Integer}) where GID <: Integer where PID <: Integer where LID <: Integer
    data.exportPIDs = exportPIDs
end

function numSameIDs(data::ImportExportData{GID, PID, LID})::LID where GID <: Integer where PID <: Integer where LID <: Integer
    data.numSameIDs
end

function numSameIDs(data::ImportExportData{GID, PID, LID}, numSame::Integer)::LID where GID <: Integer where PID <: Integer where LID <: Integer
    data.numSameIDs = numSame
end


function distributor(data::ImportExportData{GID, PID, LID})::Distributor{GID, PID, LID} where GID <: Integer where PID <: Integer where LID <: Integer
    data.distributor
end

function isLocallyComplete(data::ImportExportData{GID, PID, LID})::Bool where GID <: Integer where PID <: Integer where LID <: Integer
    data.isLocallyComplete
end

function isLocallyComplete(data::ImportExportData{GID, PID, LID}, isLocallyComplete::Bool) where GID <: Integer where PID <: Integer where LID <: Integer
    data.isLocallyComplete = isLocallyComplete
end
