############################################
### Functions for working with BAM files ###
############################################

function GenomeInfo(genome_name, reader::BioAlignments.BAM.Reader)
    GenomeInfo(genome_name,
               reader.refseqnames,
               reader.refseqlens
               )
end

function GenomicRanges(genome_name, reader::BioAlignments.BAM.Reader)
    info = GenomeInfo(genome_name, reader)
    chr = String[]
    left_pos = Int64[]
    right_pos = Int64[]
    strand_pos = Vector{Strand}()
    record = BAM.Record()
    ## FIXME: convert to genopos in the loop?
    while !eof(reader)
        read!(reader, record)
        if BAM.ismapped(record)
            push!(chr, BAM.refname(record))
            push!(left_pos, leftposition(record))
            push!(right_pos, rightposition(record))
            push!(strand_pos, strand(record))
        end
    end
    GenomicRanges(chr, left_pos, right_pos, strand_pos, info)
end

function strand(record::BAM.Record)
    ## FIXME: push up to BioAligments
    if BAM.flag(record) & 0x10 == 0
        s = STRAND_POS
    else
        s = STRAND_NEG
    end
    s
end

"""
    coverage(reader::BioAlignments.BAM.Reader)

Coverage may be calculated directly from a BAM file.

    bam_path = joinpath(Pkg.dir("GenomicVectors"),"BAM", bam_file)
    reader = open(BAM.Reader, bam_path)
    coverage(reader)
    close(reader)
"""
function coverage(reader::BioAlignments.BAM.Reader)
    # FIXME: factor out code shared with coverage(GenomicRanges)
    chrinfo = GenomeInfo("temp", reader)
    offsets = chr_offsets(chrinfo)
    out = RLEVector(0, last(chr_ends(chrinfo)))
    record = BAM.Record()
    while !eof(reader)
        read!(reader, record)
        if BAM.ismapped(record)
            chr = BAM.refname(record)
            offset = offsets[chr] # fixme
            s = leftposition(record) + offset
            e = rightposition(record) + offset
            r = s:e
            x = out[r]
            for i in 1:length(x.runvalues)
                @inbounds x.runvalues[i] = x.runvalues[i] + 1
            end
            out[r] = x
        end
        end
    out
end
