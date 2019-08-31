"""
    exactShift!(hh,qq, iq, qrows, qcols, neq)

Compute the exact shiftrights and store them in qq.
"""
function exactShift!(hh::Array{Float64,2}, qq::Array{Float64,2}, iq::Int64, qRows::Int64, qCols::Int64, neq::Int64) 

    # total number of shifts
    nexact = 0

    # functions to seperate hh
    left = 1:qCols
    right = (qCols + 1):(qCols + neq)

    
    # get right most columns of hh
    zerorows = copy(hh[:, right]')    

    # compute absolute value  
    zerorows = abs.(zerorows)

    # take the sum of the rows (aka 1st dimenison in julia)
    zerorows = Compat.sum(zerorows; dims=1)
      
    # anon function returns index of the rows who sum is 0
    zerorows = LinearIndices(zerorows)[findall(row->(row == 0), zerorows)]

    # continues until all zerorow indexes have been processed
    while length(zerorows) != 0 && (iq <= qRows)
        nz = size(zerorows, 1)

        # insert only the indexes found with zerorows into qq
        qq[(iq + 1):(iq + nz), :] = hh[zerorows, left]

	# update by shifting right by $neq columns
        hh[zerorows,:] = shiftRight!(hh[zerorows, :], neq)

        # increment the variables the amount of zerorows found
        iq = iq + nz
        nexact = nexact + nz

        # update zerorows as before but with our new hh matrix
        zerorows = hh[:, right]'
        zerorows = abs.(zerorows)
        zerorows = Compat.sum(zerorows; dims=1)
	zerorows = LinearIndices(zerorows)[findall(row->(row == 0), zerorows)]
    end # while
    
    return (hh, qq, iq, nexact)  
    
end # exactShift

