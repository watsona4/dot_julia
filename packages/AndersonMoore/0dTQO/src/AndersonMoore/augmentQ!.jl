"""
    augmentQ(qq, ww, js, iq, qrows)

Copy the eigenvectors corresponding to the largest roots into the
remaining empty rows and columns js of q 
"""
function augmentQ!(qq::Array{Float64,2}, ww::Array{Float64,2}, js::Array{Int64,2}, iq::Int64, qrows::Int64) 

    if(iq < qrows)
        lastrows = (iq + 1) : qrows
        wrows    = 1 : length(lastrows)
        qq[lastrows, js] = ww[:, wrows]'
    end

    return qq

end # augmentQ

