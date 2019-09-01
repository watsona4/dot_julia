##################################
### AbstractGenomicVector Type ###
##################################

"""
An AbstractGenomicVector is a Vector that describes positions or ranges in a
single genome, in an arbitrary order. An AbstractGenomicVector must implement
the GenomeInfo and GenoPos Interfaces. Sorting is by chromosome then by
nucleotide position.
"""
abstract type AbstractGenomicVector{T} <: AbstractVector{T} end

## Describing
genostarts(x::AbstractGenomicVector) = copy(_genostarts(x))
genoends(x::AbstractGenomicVector) = copy(_genoends(x))
strands(x::AbstractGenomicVector) = copy(_strands(x))
RLEVectors.starts(x::AbstractGenomicVector) = chrpos(_genostarts(x),chr_info(x))
RLEVectors.ends(x::AbstractGenomicVector) = chrpos(_genoends(x),chr_info(x))
RLEVectors.widths(x::AbstractGenomicVector) = (_genoends(x) - _genostarts(x)) .+ 1
RLEVectors.eachrange(x::AbstractGenomicVector) = zip(_genostarts(x),_genoends(x))
chromosomes(x::AbstractGenomicVector) = chromosomes(_genostarts(x),chr_info(x))

## FIXME: add RLEVector creation from AbstractGenomicVector and a Vector of data

### Other candidates for GenoPos Interface or AbstractGenomicVector include convert(Vector{Interval},), convert(DataFrame,x)

"""
# The GenoPos Interface

Provides access to positional information in the linearized
genome or in chromosome coordinate (e.g. chr4:1000-1020). This interface requires
a type to implement the a method on the non-copying accessors `_genostarts`,
`_genoends` and `_strands` as well as the GenomeInfo Interface.

    starts(x)
Get the starting nucleotide index for each range/position relative to the chromosome on which they lie.

    ends(x)
Get the ending nucleotide index for each range/position relative to the chromosome on which they lie.

    widths(x)
Get the distance, between the start and end nucleotide of the range, An `RleVector` of 1s for single-nucleotide positions.

    chromosomes(x)
    chromosomes(genopos, chrinfo)
Get the name of the chromosome for each range/position.

    genostarts(x)
Get the starting nucleotide index for each range/position in the linearized genome.

    genoends(x)
Get the ending nucleotide index for each range/position in the linearized genome.

    strands(x)
Get the DNA strand for each range/position, pass by copy.

    eachrange(x)
Return an iterator that returns tuples of genostart and genoend pairs.

## Utility Functions
Much of this functionality is derived from a few utility functions:

    chrpos(genopos, chrinfo)
Given positions in the linear genome, calculate the position on the relevant chromosome.

    chrindex(genopos, chrinfo)
Given positions in the linear genome, determine the corresponding chromosomes and return the indices of the chromosome in chrinfo.

    genopos(chrpos, chromosomes, chrinfo)
Given chromosome and chromosome position information and a description of
the chromosomes (a GenoPos object), calculate the corresponding positions
in the linear genome.
"""
starts, ends, widths, chromosomes, genostarts, genoends, strands, each, chrpos, genopos, chrindex

## Sorting
Base.sort(x::AbstractGenomicVector; rev::Bool=false) = sort!(copy(x))
Base.issorted(x::AbstractGenomicVector; rev::Bool=false) = issorted( eachrange(x), rev=rev )
Base.sortperm(x::AbstractGenomicVector; rev=false) = sortperm( collect(eachrange(x)), rev=rev ) # No method for iterator

## Modifying
slide(g::AbstractGenomicVector, x::Integer) = slide!( copy(g), x )

## Show
function Base.show(io::IO, x::AbstractGenomicVector)
    if length(x) > 8
        out = convert(Vector{String},x[1:8])
        Base.show_vector(io, out[1:4], "[", "")
        print(io, " … ")
        Base.show_vector(io, out[5:8], "", "]")
    else
        out = convert(Vector{String},x)
        println(io,convert(Vector{String},out))
    end
end

function Base.show(io::IO, ::MIME"text/plain", x::AbstractGenomicVector)
    show(io, summary(x))
    max_show = 25
    if length(x) > max_show
        show(io, convert(DataFrame, x[1:max_show]), rowlabel = :Loc, summary = false)
    else
        show(io, convert(DataFrame, x), rowlabel = :Loc, summary = false)
    end
end

## Indexing
Base.IndexStyle(::Type{<:AbstractGenomicVector}) = IndexLinear()
Base.getindex(x::AbstractGenomicVector,i::AbstractGenomicVector) = getindex(x, findall(in(x), y))

## Searching
_exact_overlap(el_a::Interval, el_b::Interval) = first(el_a) == first(el_b) && last(el_a) == last(el_b)

function findoverlaps(x::AbstractGenomicVector, y::AbstractGenomicVector, exact::Bool=false)
    same_genome(x, y) || throw(ArgumentError("Both inputs must be from the same genome."))
    xit = convert(IntervalCollection,x)
    yit = convert(IntervalCollection,y)
    if exact
        ol = eachoverlap(xit, yit, filter=_exact_overlap)
    else
        ol = eachoverlap(xit,yit)
    end
    ol
end

function Base.indexin(x::AbstractGenomicVector, y::AbstractGenomicVector, exact::Bool=true)
    ol = findoverlaps(x,y,exact)
    inds = Array{Union{Nothing, Int64}}(nothing, length(x))
    for (el_a,el_b) in ol
        m_a = metadata(el_a)
        m_b = metadata(el_b)
        if inds[m_a] === nothing || inds[m_a] > m_b
            inds[ m_a ] = m_b
        end
    end
    inds
end

function overlap_table(x::AbstractGenomicVector, y::AbstractGenomicVector, exact::Bool=true)
    ol = findoverlaps(x,y,exact)
    olap_pairs = [ [metadata(el_a), metadata(el_b)]' for (el_a,el_b) in ol ]
    vcat(olap_pairs...)
end

Base.in(x::AbstractGenomicVector, y::AbstractGenomicVector, exact::Bool=true) = indexin(x,y,exact) .!= nothing
Base.intersect(x::AbstractGenomicVector, y::AbstractGenomicVector, exact::Bool=true) = x[ in(x,y,exact) ]
Base.setdiff(x::AbstractGenomicVector, y::AbstractGenomicVector, exact::Bool=true) = x[in(x,y,exact) .== false]

#nearest(x::AbstractGenomicVector, query::Interval)
#
#end
#
#nearest(x::AbstractGenomicVector, query::AbstractGenomicVector)
#
#end

"""
# Searching GenomicVectors

Matching functions in `GenomicVectors` can perform overlap matching, rather than exact
matching when given the extra argument `exact=false`. In either case, the genome strand
is never considered. Other types of [overlaps](https://en.wikipedia.org/wiki/Allen%27s_interval_algebra) may
be supported in the future.

    findoverlaps(x::AbstractGenomicVector,y::AbstractGenomicVector)

Creates a `GenomicFeatures.IntersectIterator` from two `AbstractGenomicVectors`, much like the BioConductor
`findOverlaps`. This is the kernel of the other search/set operations.

    overlap_table(x::AbstractGenomicVector, y::AbstractGenomicVector, exact::Bool=true)

Creates a two column table listing the pairs of indices of x and y that overlap.

    findall(x::AbstractGenomicVector,y::AbstractGenomicVector, exact::Bool=true)

    indexin(x::AbstractGenomicVector, y::AbstractGenomicVector, exact::Bool=true)

The `AbstractGenomicVector` method on `in` is vectorized and returns a `BitArray`
that is `true` for each element of `x` that is in the set `y`.

    in(x::AbstractGenomicVector, y::AbstractGenomicVector, exact::Bool=true)

    intersect(x::AbstractGenomicVector, y::AbstractGenomicVector, exact::Bool=true)

    setdiff(x::AbstractGenomicVector, y::AbstractGenomicVector, exact::Bool=true)

"""
findoverlaps, findall, indexin, in, intersect, setdiff, nearest, overlap_table

# The discussion in https://github.com/JuliaLang/Juleps/blob/master/Find.md#particular-cases is very relevant choosing names for these functions.

# Summarizing Ranges
"""
    coverage(gr::AbstractGenomicVector)

Returns RLE giving counts of ranges in `gr` overlapping each index spanned by the full
set of ranges in `gr`.
"""
function coverage(gr::AbstractGenomicVector)
    out = RLEVector(0, last(chr_ends(gr)))
    @inbounds for (s,e) in eachrange(gr)
        r = s:e
        x = out[r]
        for i in 1:length(x.runvalues)
            @inbounds x.runvalues[i] = x.runvalues[i] + 1
        end
        out[r] = x
    end
    out
end

## Iterators
"""
Iterates over sections of a vector indexed by the genostarts and genoends of an
AbstractGenomicVector. The vector must span the full length of the genome
specified by the chr_info of the AbstractGenomicVector. This is useful for summarizing
an RLEVector of data (say DNA copy number) by genome regions (e.g. genes).
"""
struct GenomicVectorIterator{T1<:Integer,T2<:AbstractVector}
    genostarts::Vector{T1}
    genoends::Vector{T1}
    v::T2
end

"""
    vector[ AbstractGenomicVector ]

Returns an iterator over sections of a vector indexed by the genostarts and genoends of an
AbstractGenomicVector. The vector must span the full length of the genome
specified by the chr_info of the AbstractGenomicVector. This is useful for summarizing
an RLEVector of data (say DNA copy number) by genome regions (e.g. genes).
"""
function Base.getindex(v::T1, g::T2) where T2 <: AbstractGenomicVector where T1 <: RLEVector
    if length(v) != chr_ends(g)[end]
        error("When subsetting an Vector with a GenomicVector, the Vector must span the entire genome.")
    end
    GenomicVectorIterator(_genostarts(g), _genoends(g), v)
end

function Base.iterate(x::GenomicVectorIterator, state = 1)
    state > length(x) && return nothing
    newstate = state + 1
   ( x.v[ x.genostarts[state]:x.genoends[state] ], newstate )
end

function Base.length(x::GenomicVectorIterator)
    size(x.genostarts,1)
end
