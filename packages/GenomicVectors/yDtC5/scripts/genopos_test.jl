function chrpos4(x::GenomicPositions)
    offsets = chr_offsets(x.info)
    ends = chr_ends(x.info)
    len = length(ends)
    res = similar(offsets,length(x.genopos))
    r = 1
    @inbounds for (i,pos) in enumerate(x.genopos)
        if pos > ends[r]
            r = len
            r = searchsortedfirst(ends, pos, 1, r, Base.Forward)
        end
        res[i] = pos - offsets[ r ]
    end
    return(res)
end
