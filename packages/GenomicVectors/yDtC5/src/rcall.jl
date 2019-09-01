function Base.convert(::Type{Vector{String}}, strands::Vector{Strand})
    d = Dict(STRAND_POS => "+", STRAND_NEG => "-", STRAND_BOTH => "*", STRAND_NA => "*")
    [ d[x] for x in strands ]
end

function sexp(f::GenomeInfo)
    R"library(GenomicRanges)"
    s = chr_names(f)
    l = collect(chr_lengths(f))
    g = genome(f)
    R"Seqinfo($s, $l, NA, $g)"
end

function sexp(f::GenomicRanges)
    R"library(GenomicRanges)"
    s = starts(f)
    e = ends(f)
    c = chromosomes(f)
    r = convert(Vector{String}, strands(f))
    i = rcopy(chr_info(f))
    R"GRanges($c, IRanges($s, $e), $r, seqinfo = $i)"
end

function sexp(f::GenomicDataFrame)
    R"library(GenomicRanges)"
    s = starts(f)
    e = ends(f)
    c = chromosomes(f)
    r = convert(Vector{String}, strands(f))
    i = rcopy(chr_info(f))
    m = table(f)
    R"GRanges($c, IRanges($s, $e), $r, seqinfo = $i, mcols = DataFrame($m))"
end

function rcopy(::Type{GenomicDataFrame}, s::Ptr{S4Sxp})
    GenomicDataFrame(
        GenomicRanges(
            rcopy(Vector{String}, R"as.character(seqnames($s))"),
            rcopy(Vector{Int64}, R"start($s)"),
            rcopy(Vector{Int64}, R"end($s)"),
            rcopy(GenomeInfo, s[:seqinfo])
        ),
        rcopy(DataFrame, R"as.data.frame(mcols($s))")
    )
end

function rcopy(::Type{GenomeInfo}, s::Ptr{S4Sxp})
    GenomeInfo(
        rcopy(String, s[:genome][1]),
        rcopy(Vector{String}, s[:seqnames]),
        rcopy(Vector{Int64}, s[:seqlengths])
    )
end

rcopytype(::Type{RClass{:Seqinfo}}, s::Ptr{S4Sxp}) = GenomeInfo
rcopytype(::Type{RClass{:GRanges}}, s::Ptr{S4Sxp}) = GenomicDataFrame
