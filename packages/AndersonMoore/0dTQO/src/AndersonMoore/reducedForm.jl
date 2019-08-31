"""
    reducedForm(qq, qrows, qcols, bcols, condn)

Compute reduced-form coefficient matrix, b.
"""
function reducedForm(qq::Array{Float64,2}, qrows::Int64, qcols::Int64, bcols::Int64, neq::Int64, condn::Float64) 

    bb = zeros(qrows, bcols)
    
    left = 1 : (qcols - qrows)
    right = (qcols - qrows + 1) : qcols
    qtmp = similar(qq)
    
    nonsing = ( 1 / cond(qq[:, right], 1) ) > condn
     if nonsing
        qtmp[:, left] = -qq[:, right] \ qq[:, left]
        bb = qtmp[1 : neq, 1 : bcols]
    else  # rescale by dividing row by maximal qr element
        # 'inverse condition number small, rescaling '
        themax = maximum(abs.(qtmp[:, right]), 2)
        oneover = diagm(1 ./ themax[:, 1])
        
        nonsing = ( 1 / cond( oneover*qtmp[:, right], 1) ) > condn
        if nonsing
            qtmp[:, left] = -(oneover*qtmp[:, right]) \ (oneover*(qtmp[:, left]))  
            bb = qtmp[1:neq, 1:bcols]
        end
    end

    return (nonsing, bb)

end # reducedForm
