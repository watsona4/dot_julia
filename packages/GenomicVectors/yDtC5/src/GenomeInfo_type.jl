#######################
### GenomeInfo Type ###
#######################

"""
# GenomeInfo Type

Describes a genome as a collection of chromosomes arranged end-to-end in a specific order such
that the index of a nucleotide in any chromosome may be described by as single integer.

Indexing a `GenomeInfo` returns the genopos end of the indexed chromosome.

# Examples
```julia
chrinfo = GenomeInfo("hg19",["chr1","chr2","chrX"],Int64[3e5,2e5,1e4])
genome(chrinfo)
chr_names(chrinfo)
chr_lengths(chrinfo)
chr_ends(chrinfo)
chr_offsets(chrinfo)
chrinfo[2] # 5e5
```
"""
struct GenomeInfo{T,N}
    name::String
    chr_inds::OrderedDict{Symbol, T}
    chr_ends::NTuple{N,T}
    function GenomeInfo{T,N}(name::String, chrs::Vector{String}, lengths::Vector{T}) where {T <: Integer, N}
        n = name
        length(chrs) != length(lengths) && throw(ArgumentError("'chromosomes' and 'lengths' must be the same length."))
        c = OrderedDict{Symbol,T}(Symbol(x) => i for (i,x) in enumerate(chrs) )
        e = NTuple{N,T}(cumsum(lengths))
        new(n, c, e)
    end
end

function GenomeInfo(name::String, chromosomes::Vector{String}, lengths::Vector{T}) where {T<:Integer,N}
    GenomeInfo{T,length(lengths)}(name, chromosomes, lengths)
end

function Base.show(io::IO, x::GenomeInfo)
    t = typeof(x)::DataType
    show(io, t)
    write(io,"\nGenome: ", x.name)
    write(io,"\nChromosome Lengths: ")
    for (name, len) in zip(chr_names(x), chr_lengths(x))
       write(io,"\n $(name) : $(len)")
    end
end

Base.length(x::GenomeInfo) = length(x.chr_ends)
genome(x::GenomeInfo) =  x.name
chr_names(x::GenomeInfo) = collect(keys(x.chr_inds))
chr_ends(x::GenomeInfo) = collect(x.chr_ends)

function chr_offsets(x::GenomeInfo)
    ends = chr_ends(x)
    n = length(ends)
    ends[2:n] = ends[1:(n-1)]
    ends[1] = 0
    ends
end

function chr_lengths(x::GenomeInfo)
    lens = chr_ends(x)
    lens[2:end] = diff(lens)
    lens
end

Base.:(==)(x::GenomeInfo, y::GenomeInfo) = isequal(x.name,y.name) && isequal(x.chr_ends,y.chr_ends)

Base.getindex(x::GenomeInfo, i::Integer) = x.chr_ends[i]
Base.getindex(x::GenomeInfo, i::Symbol) = x.chr_ends[x.chr_inds[i]]
Base.getindex(x::GenomeInfo, i::String) = x.chr_ends[x.chr_inds[Symbol(i)]]

## GenomeInfo Interface
for op in [:chr_names, :chr_lengths, :chr_ends, :chr_offsets, :genome]
    @eval $(op)(x) = $(op)(chr_info(x))
end
same_genome(x, y) = chr_info(x) == chr_info(y)

function same_genome(x, y::Interval)
    seqname(y) != genome(x) && return false
    chrs = chromosomes( [leftposition(y),rightposition(y)], chr_info(x) )
    chrs[1] != chrs[2] && return false
    return true
end
same_genome(x::Interval, y) = same_genome(y,x)

"""
# The GenomeInfo Interface

Provides access to the name of the relevant genome
for a collection of genome positions in addition to the names, order and size
and names of the chromosomes that make up the genome. Implemented by `GenomeInfo`
and any type that implements a method on `chr_info` that returns a `GenomeInfo`.

    same_genome(x,y)
Tests if two genomes are identical.

    genome(x)
The name of the genome, e.g. hg19.

    chr_names(x)
The names of the chromosomes in the genome, in order.

    chr_lengths(x)
The lengths of the chromosomes in the genome, in order.

    chr_ends(x)
The indices of the last nucleotides in each chromosome in the genome, in order.

    chr_offsets(x)
The number of nucleotides in the preceding chromosomes in the genome, in order.

"""
chr_info, same_genome, chr_names, chr_lengths, chr_ends, chr_offsets, genome

@doc (@doc GenomeInfo), chr_info, chr_names, chr_lengths, chr_ends, chr_offsets, genome, same_genome
