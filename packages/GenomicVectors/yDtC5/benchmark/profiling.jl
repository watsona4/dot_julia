#function genopos2(pos::Vector{Int64}, chromosomes::Vector{String}, info::GenomeInfo{Int64})
function genopos2(pos, chromosomes, info)
    offsets = chr_offsets(info)
    lengths = chr_lengths(info)
    gpos = similar(offsets, length(pos))
    chr_hash = info.chr_names
    prev_chr = chromosomes[1]
    chr_ind = chr_hash[ prev_chr ]
    off = offsets[chr_ind]
    len = lengths[chr_ind]
    for i in eachindex(pos)
        chr = chromosomes[i]
        x = pos[i]
        if chr != prev_chr
            prev_chr = chr
            chr_ind = chr_hash[ chr ]
            off = offsets[chr_ind]
            len = lengths[chr_ind]
        end
        if 1 <= x <= len
            gpos[i] = x + off
        else
            error("Position $x is outside the bounds of chromosome $chr (length $(lengths[chr_ind])).")
        end
    end
    gpos
end

function genopos3(pos, chromosomes, info)
    offsets = chr_offsets(info)
    chr_hash = info.chr_names
    [ x + offsets[ chr_hash[ chr ] ] for (chr,x) in zip(chromosomes,pos) ]
end

td = load("/Users/phaverty/.julia/v0.4/GenomicRanges/test/testData/pinfo.jld")
chrpos = td["pos"]
chrnames = td["chr"]
info = td["info"]

#gp = genopos2( pos, chr, info);
@time gp = genopos( chrpos, chrnames, info)
@time gp = genopos2( chrpos, chrnames, info)
#@time gp = genopos3( chrpos, chrnames, info)
Profile.clear(); @profile gp = genopos2( chrpos, chrnames, info); ProfileView.view()
Profile.clear_malloc_data()
gp = genopos2( chrpos, chrnames, info)
