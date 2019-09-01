const ginfo = NamedTuple{(:x,:y), Tuple{Int64,Int64}}
ginfo((200,400))

NamedTuple{(:x,:y), Tuple{Int64,Int64}}((1,2))

chrs = ["chr1", "chr2", "chr3"]
lens = [100,100,100]
ends = cumsum(lens)

#chrs = Tuple( Symbol(x) for x in chrs )
#ends = Tuple( x for x in ends )

#chr_info = NamedTuple{ chrs, typeof(ends) }(ends)
#chr_info = NamedTuple{ chrs }(ends)

#x = [ :a => 1, :b => 2, :c => 3 ]
#chr_info = (x...,)

# FIXME: do something like GenomeInfo2{T,N} where {T <:Integer, N <: Integer}
struct GenomeInfo2{T <: Integer}
    name::String
    chr_ends::NamedTuple
    function GenomeInfo2{T}(name::String, chromosomes::Vector{String}, lengths::Vector{T}) where T <: Integer
        length(chromosomes) != length(lengths) && throw(ArgumentError("'chromosomes' and 'lengths' must be the same length."))
        c = Tuple( Symbol(x) for x in chrs )
        e = Tuple( x for x in cumsum(ends) )
        new(name, NamedTuple{c}(e))
    end
end

function GenomeInfo2(name::String, chromosomes::Vector{String}, lengths::Vector{T}) where T <: Integer
    GenomeInfo2{T}("hg19", chrs, ends)
end

foo = GenomeInfo2("hg19", chrs, ends)
