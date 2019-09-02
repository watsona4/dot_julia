module NormalizeQuantiles

export normalizeQuantiles,normalizeQuantiles!

export sampleRanks,sampleRanks!
export qnTiesMethods,tmMin,tmMax,tmOrder,tmReverse,tmRandom,tmAverage

using Distributed
using SharedArrays
using Random
using Statistics

@enum qnTiesMethods tmMin tmMax tmOrder tmReverse tmRandom tmAverage

function checkForNotANumber(x::Any)
    (!isa(x,Integer) && !isa(x,Real)) || isnan(x)
end

@doc "
### qnmatrix::Array{Float64} function normalizeQuantiles(matrix::AbstractArray)
Calculate the quantile normalized data for the input matrix

Parameter:
    matrix::AbstractArray
The input data as an array of values interpreted as matrix(rows,columns)

Return value: 
    qnmatrix::Array{Float64}
The quantile normalized data as Array{Float64}

Example:

    using NormalizeQuantiles

    array = [ 3.0 2.0 1.0 ; 4.0 5.0 6.0 ; 9.0 7.0 8.0 ; 5.0 2.0 8.0 ]
    qn = normalizeQuantiles(array)

    row = 2
    column = 2
    array=convert(Array{Any},array)
    array[row,column] = missing
    qn = normalizeQuantiles(array)
"
function normalizeQuantiles(matrix::AbstractArray)
    if ndims(matrix) > 2
        throw(ArgumentError("normalizeQuantiles expects an array of dimension 2"))
    end
    nrows=size(matrix,1)
    ncols=size(matrix,2)
    # preparing the result matrix
    qnmatrix=SharedArray{Float64}(nrows,ncols)
    if ncols>0 && nrows>0
        # foreach column: sort the values without NAs; put NAs (if any) back into sorted list
        NormalizeQuantiles.sortColumns!(matrix,qnmatrix,nrows,ncols)
        # foreach row: set all values to the mean of the row, except NAs
        NormalizeQuantiles.meanRows!(qnmatrix,nrows)
        # foreach column: equal values in original column should all be mean of normalized values
        # foreach column: reorder the values back to the original order
        NormalizeQuantiles.equalValuesInColumnAndOrderToOriginal!(matrix,qnmatrix,nrows,ncols)
    end
    convert(Array{Float64},qnmatrix)
end

function sortColumns!(matrix::AbstractArray,qnmatrix::SharedArray{Float64},nrows,ncols)
    @sync @distributed for column = 1:ncols
        goodIndices=[ !checkForNotANumber(x) for x in vec(matrix[:,column]) ]
        sortcol=vec(matrix[:,column])[goodIndices]
        sortcol=[Float64(x) for x in sortcol]
        sort!(sortcol)
        sortcol=Array{Float64}(sortcol)
        missingIndices=(1:nrows)[ convert(Array{Bool},reshape([!i for i in goodIndices],size(goodIndices))) ]
        isEmpty=sum(goodIndices)==0
        for missingPos in missingIndices
            if isEmpty
                isEmpty=false
                sortcol=Array{Float64}([NaN])
            else
                sortcol=vcat(sortcol[1:missingPos-1],NaN,sortcol[missingPos:end])
                #splice!(sortcol,missingPos,[NaN,sortcol[missingPos]])
            end
        end
        qnmatrix[:,column]=sortcol
    end
end

function meanRows!(qnmatrix::SharedArray{Float64},nrows)
    @sync @distributed for row = 1:nrows
        goodIndices=[ !checkForNotANumber(x) for x in qnmatrix[row,:] ]
        missingIndices=convert(Array{Bool},reshape([!i for i in goodIndices],size(goodIndices)))
        missingCount=sum(missingIndices)
        rowmean=mean([Float64(x) for x in qnmatrix[row,goodIndices]])
        qnmatrix[row,:].=Float64(rowmean)
        missingCount>0 ? qnmatrix[row,missingIndices].=NaN : false
    end
end

function equalValuesInColumnAndOrderToOriginal!(matrix::AbstractArray,qnmatrix::SharedArray{Float64},nrows,ncols)
    @sync @distributed for column = 1:ncols
        goodIndices=[ !checkForNotANumber(x) for x in vec(matrix[:,column]) ]
        sortp=[ Float64(x) for x in vec(matrix[:,column])[goodIndices] ]
        sortp=sortperm(sortp)
        goodIndices2=[ !checkForNotANumber(x) for x in vec(qnmatrix[:,column]) ]
        if length(matrix[:,column][goodIndices][sortp])>0
            allRanks=Dict{Int,Array{Int}}()
            sizehint!(allRanks,nrows)
            rankColumns=NormalizeQuantiles.getRankMatrix(matrix[:,column][goodIndices][sortp],allRanks,goodIndices)
            for i in 1:rankColumns
                rankIndices=unique(allRanks[i])
                qnmatrix[rankIndices,column].=mean([ Float64(x) for x in qnmatrix[rankIndices,column] ])
            end
        end
        qncol=Array{Float64}(undef,nrows,1)
        fill!(qncol,NaN)
        qncol[(1:nrows)[goodIndices][sortp]]=vec(qnmatrix[(1:nrows)[goodIndices2],column])
        qnmatrix[:,column]=qncol
    end
end

function getRankMatrix(sortedArrayNoNAs::AbstractArray,allRanks::Dict{Int,Array{Int}},goodIndices::Array{Bool})
    rankColumns=0
    nrows=length(sortedArrayNoNAs)
    lastValue=sortedArrayNoNAs[1]
    goodIndices2=(1:length(goodIndices))[goodIndices]
    count=1
    for i in 2:nrows
        nextValue=sortedArrayNoNAs[i]
        if !checkForNotANumber(nextValue) && !checkForNotANumber(lastValue) && nextValue==lastValue
            if haskey(allRanks,rankColumns+1)
                allRanks[rankColumns+1]=vcat(allRanks[rankColumns+1],Array{Int}([goodIndices2[i-1],goodIndices2[i]]))
            else
                allRanks[rankColumns+1]=Array{Int}([goodIndices2[i-1],goodIndices2[i]])
            end
            count+=1
        else
            if count>1
                rankColumns+=1
            end
            count=1
        end
        lastValue=sortedArrayNoNAs[i]
    end
    if count>1
        rankColumns+=1
    end
    rankColumns        
end

@doc "
### (Array{Union{Missing,Int}},Dict{Int,Array{Int}}) sampleRanks(array::AbstractArray;tiesMethod::qnTiesMethods=tmMin,naIncreasesRank=false,resultMatrix=false)

Calculate ranks of the values of a given vector.

Parameters:

    array: the input array
    tiesMethod: the method how ties (equal values) are treated
       possible values: tmMin tmMax tmOrder tmReverse tmRandom tmAverage
       default is tmMin
    naIncreasesRank: if true than any NA increases the following ranks by 1
    resultMatrix: if true than return a dictionary of rank keys and array of indices values

    If the input array can be altered use sampleRanks!(matrix::AbstractArray) to be more memory efficient.    
    
Example:
    
    using NormalizeQuantiles
    
    a = [ 5.0 2.0 4.0 3.0 1.0 ]
    
    (r,m)=sampleRanks(a)

    (r,m)=sampleRanks(a,tiesMethod=tmMin,naIncreasesRank=false,resultMatrix=true)
    
r is the vector of ranks.

m is a dictionary with rank as keys and as value the indices of all values of this rank.

"
function sampleRanks(array::AbstractArray;tiesMethod::qnTiesMethods=tmMin,naIncreasesRank=false,resultMatrix=false)
    nrows=length(array)
    goodIndices=[ !checkForNotANumber(x) for x in array ]
    reducedArray=[ Float64(x) for x in array[goodIndices] ]
    reducedArraySortedIndices=sortperm(reducedArray)
    reducedArraySorted=reducedArray[reducedArraySortedIndices]
    naCounts=similar(reducedArraySortedIndices,Int)
    naCount=0
    reducedIndex=1
    for arrayIndex in 1:length(array)
        if checkForNotANumber(array[arrayIndex])
            naCount+=1
        else
            naCounts[reducedIndex]=naCount
            reducedIndex+=1
        end
    end
    result=Array{Union{Missing,Int}}(undef,nrows)
    result[:].=missing
    rankMatrix=Dict{Int,Array{Int}}()
    group = Array{Int,1}()
    firstFound = true
    lastFound = undef
    nextRank=1
    rankIncrement=0
    doIncreaseRank=false
    headingNA=false
    groupIndex=1
    for resultIndex in 1:nrows
        if goodIndices[resultIndex]
            if headingNA
                headingNA=false
                if doIncreaseRank
                    nextRank+=rankIncrement
                    rankIncrement=0
                    doIncreaseRank=false
                end
            end
            if !firstFound && lastFound != reducedArraySorted[groupIndex]
                nextRank = setRank!(group,nextRank,tiesMethod,result,resultMatrix,rankMatrix)
                group = [naCounts[reducedArraySortedIndices[groupIndex]]+reducedArraySortedIndices[groupIndex]]
                if doIncreaseRank
                    nextRank+=rankIncrement
                    rankIncrement=0
                    doIncreaseRank=false
                end
            else
                push!(group,naCounts[reducedArraySortedIndices[groupIndex]]+reducedArraySortedIndices[groupIndex])
            end
            lastFound = reducedArraySorted[groupIndex]
            firstFound = false
            groupIndex+=1
        else
            if naIncreasesRank
                doIncreaseRank=true
                rankIncrement+=1
            end
            if firstFound
                headingNA=true
            end
        end
    end
    setRank!(group,nextRank,tiesMethod,result,resultMatrix,rankMatrix)
    (result,rankMatrix)
end 

function setRank!(group,nextRank,tiesMethod,result,resultMatrix,rankMatrix)
    ranksCount=length(group)
    ranks=nextRank:(nextRank+ranksCount-1)
    if tiesMethod==tmMin
        minRank=minimum(ranks)
        result[group].=minRank
        if resultMatrix
            rankMatrix[minRank]=group
        end
        nextRank+=1
    elseif tiesMethod==tmMax
        maxRank=maximum(ranks)
        result[group].=maxRank
        if resultMatrix
            rankMatrix[maxRank]=group
        end
        nextRank=maxRank+1
    elseif tiesMethod==tmOrder
        maxRank=maximum(ranks)
        result[group]=ranks
        if resultMatrix
            for rankIndex in 1:length(ranks)
                rankMatrix[ranks[rankIndex]]=[group[rankIndex]]
            end
        end
        nextRank=maxRank+1
    elseif tiesMethod==tmReverse
        maxRank=maximum(ranks)
        ranks=reverse(ranks,dims=1)
        result[group]=ranks
        if resultMatrix
            for rankIndex in 1:length(ranks)
                rankMatrix[ranks[rankIndex]]=[group[rankIndex]]
            end
        end
        nextRank=maxRank+1
    elseif tiesMethod==tmRandom
        maxRank=maximum(ranks)
        ranks=ranks[randperm(ranksCount)]
        result[group]=ranks
        if resultMatrix
            for rankIndex in 1:length(ranks)
                rankMatrix[ranks[rankIndex]]=[group[rankIndex]]
            end
        end
        nextRank=maxRank+1
    elseif tiesMethod==tmAverage
        rankMean=round(Int,mean(ranks))
        result[group].=rankMean
        if resultMatrix
            rankMatrix[rankMean]=group
        end
        nextRank=rankMean+1
    end
    nextRank
end


end # module
