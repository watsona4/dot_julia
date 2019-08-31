function sameSpan(aVecs::Array{Float64,2},bVecs::Array{Float64,2})
    aRank=rank(aVecs)
    bRank=rank(bVecs)
    bothRank=rank(vcat(aVecs,bVecs),10e-12)
    aRank==bRank==bothRank
end    
