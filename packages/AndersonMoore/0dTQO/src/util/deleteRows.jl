"""
    deleteRows(x, rowss)

Delete rows from a 2x2 matrix. Use Float or Int array for x.
"""
function deleteRows(xIn::Array{Float64, 2}, rows::Array{Int64, 1})
    
    # get dimensions of input
    (numRows, numCols) = size(xIn)

    # for calculating new dimensions
    numRowDelete = length(rows)
    
    # uninitialized array with new dimensions
    xOut = Array{Float64}(undef, (numRows - numRowDelete), numCols)
    
    # dynamically build new matrix without columns to delete
    xIndexIn  = 1
    xIndexOut = 1
    for ii in rows
        xRowsIn =  xIndexIn : (ii - 1) 
        xRowsOut =  xIndexOut : xIndexOut + length(xRowsIn) - 1 
              
        # setting xOut cols to xIn, xColsOut always <= xColsIn
        xOut[xRowsOut, :] = xIn[xRowsIn, :]

        xIndexIn = ii + 1
        xIndexOut = xIndexOut + length(xRowsIn)
    end

    # need one more iteration to get last section of cols
    if xIndexIn <= numRows
        xRowsIn = xIndexIn : numRows
        xRowsOut = xIndexOut : xIndexOut + length(xRowsIn) - 1

        xOut[xRowsOut, :] = xIn[xRowsIn, :]
    end

    return xOut
end
