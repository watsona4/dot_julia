"""
    numericShift!(hh, qq, iq, qrows, qcols, neq, condn)

Compute the numeric shiftrights and store them in q.
"""
function numericShift!(hh::Array{Float64,2}, qq::Array{Float64,2}, iq::Int64, qRows::Int64, qCols::Int64, neq::Int64, condn::Float64) 

    # total number of shifts
    nnumeric = 0
    
    # functions to seperate hh
    left = 1:qCols
    right = (qCols + 1):(qCols + neq)

    # preform QR factorization on right side of hh
    F = Compat.qr(hh[:, right], Val(true))

    # filter R only keeping rows that are zero
    Q, R = F
    zerorows = abs.(diag(R))
    zerorows = findall(x->(float(x) <= condn), zerorows)

    while (length(zerorows) != 0) && (iq <= qRows)
        # update hh with matrix multiplication of Q and hh
        hh = *(Q', hh)

        # need total number of zero rows
        nz = size(zerorows, 1)

        # update qq to keep track of rows that are zero
        qq[(iq + 1):(iq + nz), :] = hh[zerorows, left]

        # update hh by shifting right
        hh[zerorows, :] = shiftRight!(hh[zerorows, :], neq)

        # increment our variables by number of shifts
        iq = iq + nz
        nnumeric = nnumeric + nz

        # redo QR factorization and filter R as before
        F = Compat.qr(hh[:, right], Val(true))
	Q, R = F
        zerorows = abs.(diag(R))
        zerorows = findall(x->(float(x) <= condn), zerorows)

    end # while
    
    return(hh, qq, iq, nnumeric)

end # numericShift
