"""
Contains the data for a BlockMap
"""
mutable struct BlockMapData{GID <: Integer, PID <:Integer, LID <: Integer}
    comm::Comm{GID, PID, LID}
    directory::Union{Directory, Nothing}
    lid::Vector{LID}
    myGlobalElements::Vector{GID}
#    firstPointInElementList::Array{Integer}
#    elementSizeList::Array{Integer}
#    pointToElementList::Array{Integer}

    numGlobalElements::GID
    numMyElements::LID
#    elementSize::Integer
#    minMyElementSize::Integer
#    maxMyElementSize::Integer
#    minElementSize::Integer
#    maxElementSize::Integer
    minAllGID::GID
    maxAllGID::GID
    minMyGID::GID
    maxMyGID::GID
    minLID::LID
    maxLID::LID
#    numGlobalPoints::Integer
#    numMyPoints::Integer

#    constantElementSize::Bool
    linearMap::Bool
    distributedGlobal::Bool
    oneToOneIsDetermined::Bool
    oneToOne::Bool
    lastContiguousGID::GID
    lastContiguousGIDLoc::GID
    lidHash::Dict{GID, LID}
end

function BlockMapData(numGlobalElements::GID, comm::Comm{GID, PID, LID}) where GID <: Integer where PID <: Integer where LID <: Integer
    BlockMapData(
        comm,
        nothing,
        LID[],
        GID[],

        numGlobalElements,
        LID(0),
        GID(0),
        GID(0),
        GID(0),
        GID(0),
        LID(0),
        LID(0),

        false,
        false,
        false,
        false,
        GID(0),
        GID(0),
        Dict{GID, LID}()
    )
end
