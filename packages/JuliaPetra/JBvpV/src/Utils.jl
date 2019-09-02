
#minor utility code that does belong anywhere else

#used in implementation of CSRGraph and CSRMatrix
function computeOffsets(rowPtrs::AbstractArray{<: Integer, 1}, numEnts::Integer)
    numOffsets = length(rowPtrs)
    @simd for i = 1:numOffsets
        @inbounds rowPtrs[i] = numEnts*(i-1)+1
    end
    rowPtrs
end
function computeOffsets(rowPtrs::AbstractArray{<: Integer, 1}, numEnts::Array{<: Integer, 1})
    numOffsets = length(rowPtrs)
    numCounts = length(numEnts)
    if numCounts >= numOffsets
        throw(InvalidArgumentError("length(numEnts) = $numCounts "
                * ">= length(rowPtrs) = $numOffsets"))
    end
    sum = 1
    for i = 1:numCounts
        @inbounds rowPtrs[i] = sum
        @inbounds sum += numEnts[i]
    end
    @inbounds rowPtrs[numCounts+1:numOffsets] .= sum
    sum-1
end



export InvalidArgumentError
"""
    InvalidArgumentError(msg)

The values passed as arguments are not valid.  Argument `msg`
is a descriptive error string.
"""
struct InvalidArgumentError <: Exception
    msg::AbstractString
end


export InvalidStateError
"""
    InvalidStateError(msg)

An object is not in a valid state for this method.  Argument `msg`
is a descriptive error string.
"""
struct InvalidStateError <: Exception
    msg::AbstractString
end
