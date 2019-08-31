"""
    deleteCols(x, cols)

Delete columns from a 2x2 matrix. Use Float or Int array for x.
"""
function deleteCols(xIn, cols::Array{Int64, 1})
    
    # get dimensions of input
    (numRows, numCols) = size(xIn)

    # for calculating new dimensions
    numColDelete = length(cols)

    # uninitialized array with new dimensions
    xOut = Array{Float64}(undef, numRows, (numCols - numColDelete))

    # dynamically build new matrix without columns to delete
    xIndexIn  = 1
    xIndexOut = 1
    for ii in cols 
        xColsIn =  xIndexIn : (ii - 1) 
        xColsOut =  xIndexOut : xIndexOut + length(xColsIn) - 1 
        
        # setting xOut cols to xIn, xColsOut always <= xColsIn
        xOut[:, xColsOut] = xIn[:, xColsIn]

        xIndexIn = ii + 1
        xIndexOut = xIndexOut + length(xColsIn)
    end

    # need one more iteration to get last section of cols
    if xIndexIn <= numCols
        xColsIn = xIndexIn : numCols
        xColsOut = xIndexOut : xIndexOut + length(xColsIn) - 1

        xOut[:, xColsOut] = xIn[:, xColsIn]
    end

    return xOut
end
