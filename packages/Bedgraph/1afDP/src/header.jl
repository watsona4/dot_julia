mutable struct BedgraphHeader{T} #TODO: determine what and how this will be.
    data::T
end

function Base.convert(::Type{String}, header::BedgraphHeader{Vector{String}}) :: String

    str = ""
    for line in header.data
        str = string(str, line, '\n')
    end

    return str
end

function generateBasicHeader(records::Vector{Record}; bump_forward=true) :: BedgraphHeader{Vector{String}} #Note: we assume that records are sorted by chrom and left position.

    chrom = records[1].chrom

    pos_start = records[1].first
    pos_end = records[end].last

    if bump_forward
        pos_start = pos_start + 1
        pos_end = pos_end + 1
    end

    return BedgraphHeader(["browser position $chrom:$pos_start-$pos_end", "track type=bedGraph"])
end

generateBasicHeader(chrom::String, pos_start::Int, pos_end::Int; bump_forward=true) = generateBasicHeader([Record(chrom, pos_start, pos_end, 0)], bump_forward=bump_forward)

function _readHeader(io) :: Vector{String}
    position(io) == 0 || seekstart(io)

    header = String[]
    line = readline(io)

    while !eof(io) && !isLikeRecord(line) # TODO: seek more rebust check.
        push!(header, line)
        line = readline(io)
    end

    return header
end

function Base.read(io::IO, ::Type{BedgraphHeader{Vector{String}}}) :: BedgraphHeader{Vector{String} }
    return BedgraphHeader(_readHeader(io))
end

function Base.write(io::IO, header::BedgraphHeader{Vector{String}})
    return Base.write(io, convert(String, header))
end
