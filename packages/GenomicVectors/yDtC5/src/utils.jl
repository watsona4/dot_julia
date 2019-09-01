#########################
### Utility Functions ###
#########################

function genopos(positions, chromosomes, chrinfo::GenomeInfo)
    if length(positions) != length(chromosomes)
        throw(ArgumentError("Arguments positions and chromosomes must have the same length."))
    end
    offsets = chr_offsets(chrinfo)
    lengths = chr_lengths(chrinfo)
    chr_inds = chrinfo.chr_inds
    gpos = similar(positions)
    prev_chr = Symbol(chromosomes[1])
    prev_chr_ind = chr_inds[prev_chr]
    len = lengths[prev_chr_ind]
    o = offsets[prev_chr_ind]
    @inbounds for i in 1:length(positions)
        chr = Symbol(chromosomes[i])
        x = positions[i]
        if chr != prev_chr
            prev_chr = chr
            prev_chr_ind = chr_inds[prev_chr]
            len = lengths[prev_chr_ind]
            o = offsets[prev_chr_ind]
        end
        if 1 <= x <= len
            gpos[i] = x + o
        else
            error("Position $x is outside the bounds of chromosome $chr (length $(lengths[prev_chr])).")
        end
    end
    gpos
end

function chrindex(positions, chrinfo::GenomeInfo)
    ends = chr_ends(chrinfo)
    offsets = chr_offsets(chrinfo)
    res = Vector{Int64}(undef, length(positions))
    i = r = 1
    e = ends[r]
    o = offsets[r]
    @inbounds for g in positions
        if g > e || g <= o # Need to switch chromosome
            r = 1
            while g > ends[r] # Linear search
                r = r + 1
            end
            e = ends[r]
            o = offsets[r]
        end
        res[i] = r
        i = i + 1
    end
    res
end

function chrpos(positions, chrinfo::GenomeInfo)
    ends = chr_ends(chrinfo)
    offsets = chr_offsets(chrinfo)
    res = similar(positions)
    i = r = 1
    e = ends[r]
    o = offsets[r]
    @inbounds for g in positions
        if g > e || g <= o # Need to switch chromosome
            r = 1
            while g > ends[r] # Linear search
                r = r + 1
            end
            e = ends[r]
            o = offsets[r]
        end
        res[i] = g - o
        i = i + 1
    end
    res
end

function chromosomes(positions, chrinfo::GenomeInfo)
    ends = chr_ends(chrinfo)
    offsets = chr_offsets(chrinfo)
    chrs = chr_names(chrinfo)
    res = Vector{Symbol}(undef, length(positions))
    i = r = 1
    e = ends[r]
    o = offsets[r]
    @inbounds for g in positions
        if g > ends[r] || g <= offsets[r] # Need to switch chromosome
            r = 1
            while g > ends[r] # Linear search
                r = r + 1
            end
            e = ends[r]
            o = offsets[r]
        end
        res[i] = chrs[r]
        i = i + 1
    end
    res
end
