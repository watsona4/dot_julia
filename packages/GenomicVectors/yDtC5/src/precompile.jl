function _precompile_()
    precompile( GenomeInfo, (String, Vector{String}, Vector{Int}) )
    precompile( GenomicPositions, (Vector{Int}, Vector{String}, GenomeInfo{Int}) )
end
