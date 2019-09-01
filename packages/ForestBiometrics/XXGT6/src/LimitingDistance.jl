## Variable radius plot limiting distance
function limiting_distance(baf::Int,dbh::Float64,horizontal_distance::Float64)
    prf = sqrt(75.625/baf)
    ld::Float64=dbh*prf
    if ld>horizontal_distance
        return("The tree is in")
    else
        return("The tree is out")
    end
end
