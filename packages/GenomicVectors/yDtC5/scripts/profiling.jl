using GenomicVectors
using JLD
using RLEVectors
using AxisArrays
using DataFrames

ordered_chrnames = vcat(["$i" for i in 1:22], ["X","Y"] )

ds = load("/Users/phaverty/.julia/v0.4/GenomicRanges.bak/test/testData/pinfo.jld")

p = ds["pos"]
c = convert(Vector{String},ds["chr"])

dt = DataFrame([ c,p ],[:chr,:pos])
dt = sort(dt,cols=[:chr,:pos])
chr_rle = RLEVector(dt[:chr])
cn = convert(Vector{String},values(chr_rle))
cmax = tapply(dt[:pos],chr_rle,maximum)
cl = AxisArray( cmax, cn )
cl = [cl[i] for i in ordered_chrnames]

info = GenomeInfo("hg19",ordered_chrnames,cl)

gp = genopos( p, c, info)
x = GenomicPositions( p, c, info )
y = GenomicRanges(p, p, info )

gp_rand = gp[shuffle(1:length(gp))]

function chrpos2(p, chrinfo::GenomeInfo)
    ends = chr_ends(chrinfo)
    offsets = chr_offsets(chrinfo)
    nchr = length(ends)
    res = similar(p,length(p))
    r = 1
    i = 1
    @inbounds for g in p
        if g > ends[r] || g <= offsets[r]
            r = searchsortedfirst(ends, g, 1, nchr, Base.Forward)
        end
        r = min(r,nchr)
        res[i] = p[i] - offsets[ r ]
        i = i + 1
    end
    res
end

function chrpos3(p, chrinfo::GenomeInfo)
    ends = chr_ends(chrinfo)
    offsets = chr_offsets(chrinfo)
    nchr = length(ends)
    res = similar(p,length(p))
    r = 1
    i = 1
    @inbounds for g in p
        if g > ends[r] || g <= offsets[r]
            r = 1
            while g > ends[r]
                r = r + 1
            end
        end
        res[i] = p[i] - offsets[r]
        i = i + 1
    end
    res
end

#using ProfileView
#Profile.clear(); @profile for i in 1:1e2 gp = genopos( p, c, info); end; ProfileView.view()
#Profile.clear(); @profile for i in 1:1e2 gp = chrpos(x); end; ProfileView.view()
#Profile.clear(); @profile for i in 1:1e2 gp = chr(x); end; ProfileView.view()

function genopos2(positions, chromosomes, chrinfo::GenomeInfo)
    if length(positions) != length(chromosomes)
        throw(ArgumentError("Arguments positions and chromosomes must have the same length."))
    end
    offsets = chr_offsets(chrinfo)
    lengths = chr_lengths(chrinfo)
    gpos = similar(offsets, length(positions))
    prev_chr = chromosomes[1]
    len = lengths[prev_chr]
    @inbounds for (i,x,chr) in zip(1:length(positions), positions, chromosomes)
        if chr != prev_chr
            prev_chr = chr
            len = lengths[prev_chr]
        end
        if 1 <= x <= len
            gpos[i] = x + offsets[prev_chr]
        else
            error("Position $x is outside the bounds of chromosome $chr (length $(lengths[prev_chr])).")
        end
    end
    gpos
end

function genopos3(positions, chromosomes, chrinfo::GenomeInfo)
    if length(positions) != length(chromosomes)
        throw(ArgumentError("Arguments positions and chromosomes must have the same length."))
    end
    offsets = chr_offsets(chrinfo)
    lengths = chr_lengths(chrinfo)
    chrnames = chr_names(chrinfo)
    gpos = similar(offsets, length(positions))
    prev_chr = chromosomes[1]
    prev_chrind = findall(in(chrnames), [prev_chr])[1]
    len = lengths[prev_chrind]
    o = offsets[prev_chrind]
    @inbounds for (i,x,chr) in zip(1:length(positions), positions, chromosomes)
        if chr != prev_chr
            prev_chr = chr
            prev_chrind = findin([prev_chr],chrnames)[1]
            len = lengths[prev_chrind]
            o = offsets[prev_chrind]
        end
        if 1 <= x <= lengths[prev_chrind]
            gpos[i] = x + o
        else
            error("Position $x is outside the bounds of chromosome $chr (length $(lengths[prev_chr])).")
        end
    end
    gpos
end

function genopos4(positions, chromosomes, chrinfo::GenomeInfo)
    if length(positions) != length(chromosomes)
        throw(ArgumentError("Arguments positions and chromosomes must have the same length."))
    end
    offsets = chr_offsets(chrinfo)
    lengths = chr_lengths(chrinfo)
    gpos = similar(offsets, length(positions))
    prev_chr = chromosomes[1]
    len = lengths[prev_chr]
    o = offsets[prev_chr]
    @inbounds for (i,x,chr) in zip(1:length(positions), positions, chromosomes)
        if chr != prev_chr
            prev_chr = chr
            len = lengths[prev_chr]
            o = offsets[prev_chr]
        end
        if 1 <= x <= len
            gpos[i] = x + o
        else
            error("Position $x is outside the bounds of chromosome $chr (length $(lengths[prev_chr])).")
        end
    end
    gpos
end

@time for i in 1:10 genopos2( p,c, info ); end
@time for i in 1:10 genopos3( p,c, info ); end
@time for i in 1:10 genopos4( p,c, info ); end
