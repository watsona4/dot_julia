######################
### GenomicRanges Type
######################

"""
# GenomicRanges Type

Represents closed ranges in a genome. This type uses
its (immutable) `GenomeInfo` slot object to describe corresponding
genome and positions can be expressed relative to this concatenated,
linearized genome or relative to the chromosome containing a given position.

# Examples
```julia
    chrinfo = GenomeInfo("hg19",["chr1","chr2","chrX"],Int64[3e5,2e5,1e4])
    chrs = ["chr1","chr2","chr2","chrX"]
    starts = [100, 200, 300, 400]
    ends = [120, 240, 350, 455]
    gr = GenomicRanges(chrs,starts,ends,chrinfo)
```
# Indexing
Indexing a `GenomicRanges` with an array produces a new `GenomicRanges`.

Getting/setting by a scalar gives/takes a GenomicFeatures.Interval. The leftposition and
rightposition in this Interval must be in genome location units and correspond to the
same chromosome. The seqname must match the genome of the GenomicRanges. Outgoing Intervals
will have the index `i` as their metadata. This makes it possible to obtain the original
ordering if Intervals after conversion to, say, an IntervalCollection. Any metadata
for an incoming Interval is ignored.

The `each` function produces an iterator of (start,end) two-tuples in genome location
units. This is use for many internal functions, like sorting. This is intentionally
similar to `RLEVectors.each`.

"""
struct GenomicRanges{T <: Integer,N} <: AbstractGenomicVector{T}
    starts::Vector{T}
    ends::Vector{T}
    strands::Vector{Strand}
    chrinfo::GenomeInfo{T,N}
    function GenomicRanges{T,N}(starts, ends, strands, chrinfo) where {T <: Integer,N}
        length(starts) != length(ends) && throw(ArgumentError("starts and ends must be of the same length."))
        if strands == nothing
            strands = Vector{Strand}(undef, length(starts))
            fill!(strands,STRAND_NA)
        else
            if length(starts) != length(strands)
                throw(ArgumentError("starts, ends and stands must be of the same length."))
            end
        end
        new(starts, ends, strands, chrinfo)
    end
end

## Create with specified strands
GenomicRanges(chrs::Vector{String}, starts::Vector{T}, ends::Vector{T}, strands::Vector{Char}, chrinfo::GenomeInfo{T,N}) where {T <: Integer,N} = GenomicRanges{T,N}(genopos(starts,chrs,chrinfo), genopos(ends,chrs,chrinfo),strands,chrinfo)
GenomicRanges(chrs::Vector{String}, starts::Vector{T}, ends::Vector{T}, strands::Vector{Strand}, chrinfo::GenomeInfo{T,N}) where {T <: Integer,N} = GenomicRanges{T,N}(genopos(starts,chrs,chrinfo), genopos(ends,chrs,chrinfo),strands,chrinfo)
GenomicRanges(genostarts::Vector{T}, genoends::Vector{T}, strands::Vector{Char}, chrinfo::GenomeInfo{T,N}) where {T <: Integer,N} = GenomicRanges{T,N}(genostarts,genoends,strands,chrinfo)
GenomicRanges(genostarts::Vector{T}, genoends::Vector{T}, strands::Vector{Strand}, chrinfo::GenomeInfo{T,N}) where {T <: Integer,N} = GenomicRanges{T,N}(genostarts,genoends,strands,chrinfo)

## Create with default strands
GenomicRanges(chrs::Vector{String}, starts::Vector{T}, ends::Vector{T}, chrinfo::GenomeInfo{T,N}) where {T <: Integer,N} = GenomicRanges{T,N}(genopos(starts,chrs,chrinfo), genopos(ends,chrs,chrinfo), nothing, chrinfo)
GenomicRanges(genostarts::Vector{T}, genoends::Vector{T}, chrinfo::GenomeInfo{T,N}) where {T <: Integer,N} = GenomicRanges{T,N}(genostarts,genoends,nothing,chrinfo)

## For GenomeInfo Interface
chr_info(x::GenomicRanges) = x.chrinfo

## For GenoPos Interface
_genostarts(x::GenomicRanges) = x.starts # Pass by reference for internal use
_genoends(x::GenomicRanges) = x.ends # Pass by reference for internal use
_strands(x::GenomicRanges) = x.strands # Pass by reference for internal use

## Indexing
Base.getindex(x::GenomicRanges, i::Int) = Interval(String(genome(x)),x.starts[i],x.ends[i],x.strands[i],i)

function Base.setindex!(x::GenomicRanges, value::Interval, i::Int)
    if !same_genome(x,value)
        throw(ArgumentError("Arguments x and value must must be of the same genome."))
    end
    x.starts[i] = leftposition(value)
    x.ends[i] = rightposition(value)
    x.strands[i] = strand(value)
    return(x)
end

function Base.getindex(x::GenomicRanges, i::AbstractArray)
    GenomicRanges( x.starts[i], x.ends[i], x.strands[i], chr_info(x) )
end

#function Base.setindex!(x::GenomicRanges, value::GenomicRanges, i::AbstractArray)
#
#end

## Conversions
function Base.convert(::Type{DataFrame}, x::GenomicRanges)
    n = length(x)
    chrs = [String(i) for i in chr_names(x)]
    c_res = Vector{String}(undef, n)
    s_res = similar(x.starts, n)
    e_res = similar(x.ends, n)
    ends = chr_ends(x.chrinfo)
    offsets = chr_offsets(x.chrinfo)
    i = r = 1
    e = ends[r]
    o = offsets[r]
    c = chrs[r]
    @inbounds for (spos,epos) in eachrange(x)
        if spos > e || spos <= o
            r = 1
            while spos > ends[r]
                r = r + 1
            end
            e = ends[r]
            o = offsets[r]
            c = chrs[r]
        end
        c_res[i] = c
        s_res[i] = spos - o
        e_res[i] = epos - o
        i = i + 1
    end
    DataFrame( Chromosome = c_res, Start = s_res, End = e_res, Strand = _strands(x) )
end

function Base.convert(::Type{Vector{String}}, x::GenomicRanges)
    df = convert(DataFrame,x)
    String[ string(c, ":", s, "-", e) for (c,s,e) in zip(df[:Chromosome], df[:Start], df[:End]) ]
end

Base.convert(::Type{Vector}, x::GenomicRanges) = collect(eachrange(x))
Base.convert(::Type{GenomicPositions}, x::GenomicRanges) = GenomicPositions(genostarts(x), chr_info(x))

"""
Conversion of GenomicRanges to IntervalCollection adds index as metadata in order to recover order later.
"""
function Base.convert(::Type{IntervalCollection}, x::GenomicRanges)
    g = String(genome(x))
    IntervalCollection( sort( [i for i in x] ) )
end

## Altering Positions
"""
    slide!(gr::GenomicRanges, x::Integer)
"""
function slide!(gr::GenomicRanges, x::Integer)
    offsets = chr_offsets(gr)
    ends = collect(chr_ends(gr))
    n_chrs = length(ends)
    chr_ind = 1
    i = 1
    for (s,e) in eachrange(gr)
        if e > ends[chr_ind] || s <= offsets[chr_ind] # Find new chr
            chr_ind = searchsortedfirst(ends, s, one(Int64), n_chrs, Base.Forward)
        end
        news = s + x
        newe = e + x
        if newe > ends[chr_ind] || news <= offsets[chr_ind]
            throw(ArgumentError("Genomic position ($s,$e) falls outside the bounds of chromosome $(chr_names(gr)[chr_ind]) when shifted by $x."))
        end
        gr.starts[i] = news
        gr.ends[i] = newe
        i = i + 1
    end
    gr
end

function Base.empty!(x::GenomicRanges)
    empty!(x.starts)
    empty!(x.ends)
    empty!(x.strands)
    x
end

function Base.vcat(x::GenomicRanges,y::GenomicRanges)
    same_genome(x, y) || throw(ArgumentError("Both GenomicPositions must be from the same genome."))
    GenomicRanges(vcat(x.starts,y.starts),vcat(x.ends,y.ends),vcat(x.strands,y.strands),chr_info(x))
end

## Sorting
function Base.sort!(x::GenomicRanges; rev::Bool=false)
    ind = sortperm(x,rev=rev)
    x.starts[:] = x.starts[ind]
    x.ends[:] = x.ends[ind]
    x.strands[:] = x.strands[ind]
    x
end

## Querying Positions
# Note that the standard set operations require exact matches and
# a separate set of functions work on overlaps
# N.B. intersect(tree1,tree2) returns an iterator of overlapping pairs. This is like
# The twocol matrix of match pairs in R's IRanges::findOverlaps()

# Identical matches (set ops)

function Base.union(x::GenomicRanges, y::GenomicRanges)
    ic = convert(IntervalCollection,vcat(x,y))
    ic = unique(ic)
    inds = [ metadata(el) for el in ic ]
    gr = GenomicRanges( [ first(el) for el in ic ], [ last(el) for el in ic ], [ strand(el) for el in ic ], chr_info(x) )
    gr = gr[inds]
    gr
end

# Overlap ops
"""
Returns an edited version of `x` where ranges or parts of ranges overlapping
a range in `y` are removed.
"""
function remove_overlaps(x::GenomicRanges, y::AbstractGenomicVector)

end

"""
Returns an edited version of `x` where only ranges or parts of ranges overlapping
a range in `y` are kept. BioConductor calls this operation `reduce`.
"""
function select_overlaps(x::GenomicRanges, y::AbstractGenomicVector)

end

"""
Merges overlapping ranges
"""
function collapse(gr::GenomicRanges)
    out = similar(gr)
    fill!(out.strands, STRAND_NA)  # move me to GenomicFeatures.similar
    if issorted(gr)
        x = gr
    else
        x = sort(gr)
    end
    current_end = 0
    i = 0
    for (s,e) in eachrange(x)
        if s > current_end
            i = i + 1
            _genostarts(out)[i] = s
        end
        if e > current_end
            _genoends(out)[i] = current_end = e
        end
    end
    resize!(out, i)
    out
end

"""
Splits overlapping ranges to create a disjoint set of ranges
"""
function disjoin(gr::GenomicRanges)
    out = GenomicRanges( sort(_genostarts(gr)), sort(_genoends(gr)), chr_info(gr))
    n = length(out)
    current_end = next_start = 0
    i = 1
    while i < n
#        println("i is ", i, " and n is ", n)
        next_start = _genostarts(out)[i + 1]
        current_end = _genoends(out)[i]
        if next_start <= current_end
#            println("splitting ...")
            insert!(_genoends(out), i, next_start - 1)
            insert!(_genostarts(out), i + 2, current_end + 1)
            insert!(_strands(out), i, STRAND_NA)
            n = n + 1
#        else
#            println("NOT splitting ...")
        end
        i = i + 1
    end
    out
end

"""
Returns GenomicRanges of regions between collapsed input ranges, e.g. introns
"""
function gaps(gr::GenomicRanges)
    x = collapse(gr)
    out = similar(gr, length(x) - 1)
    fill!(out.strands, STRAND_NA) # move me to GenomicFeatures.similar
    for i in 1:length(out)
        _genostarts(out)[i] = _genoends(x)[i] + 1
        _genoends(out)[i] = _genostarts(x)[i + 1] - 1
    end
    out
end
