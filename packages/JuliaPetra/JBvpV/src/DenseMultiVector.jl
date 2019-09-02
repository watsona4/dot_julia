export DenseMultiVector

"""
DenseMultiVector represents a dense multi-vector.  Note that all the vectors in a single DenseMultiVector are the same size
"""
mutable struct DenseMultiVector{Data <: Number, GID <: Integer, PID <: Integer, LID <: Integer} <: MultiVector{Data, GID, PID, LID}
    data::Array{Data, 2} # data[1, 2] is the first element of the second vector
    numVectors::LID

    map::BlockMap{GID, PID, LID}
end

## Constructors ##

"""
    DenseMultiVector{Data}(::BlockMap{GID, PID, LID}, numVecs::Integer, zeroOut=true)

Creates a new DenseMultiVector based on the given map
"""
function DenseMultiVector{Data}(map::BlockMap{GID, PID, LID}, numVecs::Integer, zeroOut=true) where {Data <: Number, GID <: Integer, PID <: Integer, LID <: Integer}
    localLength = numMyElements(map)
    if zeroOut
        data = zeros(Data, (localLength, numVecs))
    else
        data = Array{Data, 2}(undef, localLength, numVecs)
    end
    DenseMultiVector{Data, GID, PID, LID}(data, numVecs, map)
end

"""
    DenseMultiVector(map::BlockMap{GID, PID, LID}, data::AbstractArray{Data, 2})

Creates a new DenseMultiVector wrapping the given array.  Changes to the DenseMultiVector or Array will affect the other
"""
function DenseMultiVector(map::BlockMap{GID, PID, LID}, data::AbstractArray{Data, 2}) where {Data <: Number, GID <: Integer, PID <: Integer, LID <: Integer}
    localLength = numMyElements(map)
    if size(data, 1) != localLength
        throw(InvalidArgumentError("Length of vectors does not match local length indicated by map"))
    end
    DenseMultiVector{Data, GID, PID, LID}(data, size(data, 2), map)
end

## External methods ##

numVectors(mVect::DenseMultiVector) = mVect.numVectors
getMap(mVect::DenseMultiVector) = mVect.map
getLocalArray(mVect::DenseMultiVector) = mVect.data


function Base.copy(vect::DenseMultiVector{Data, GID, PID, LID})::DenseMultiVector{Data, GID, PID, LID} where {Data <: Number, GID <: Integer, PID <: Integer, LID <: Integer}
    DenseMultiVector{Data, GID, PID, LID}(copy(vect.data), vect.numVectors, vect.map)
end

function Base.copyto!(dest::DenseMultiVector{Data, GID, PID, LID}, src::DenseMultiVector{Data, GID, PID, LID})::DenseMultiVector{Data, GID, PID, LID} where {Data, GID, PID, LID}
    copyto!(dest.data, src.data)
    dest.numVectors = src.numVectors
    dest.map = src.map

    dest
end
