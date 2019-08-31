export Record

struct Record
    chrom::String
    first::Int
    last::Int
    value::Real
end

function Base.:(==)(a::Record, b::Record)
    return a.chrom  == b.chrom &&
           a.first == b.first &&
           a.last == b.last &&
           a.value == b.value
end

function Base.isless(a::Record, b::Record, chrom_isless::Function=isless) :: Bool
    if a.chrom != b.chrom
        return chrom_isless(a.chrom, b.chrom) :: Bool
    elseif a.first != b.first
        return a.first < b.first
    elseif a.last != b.last
        return a.last < b.last
    elseif a.value != b.value
        return a.value < b.value
    else
        return false
    end
end

function Record(data::Vector{String})
    return convert(Record, data)
end

function Base.convert(::Type{Record}, data::Vector{String}) :: Record
    chrom, first, last, value = _convertCells(data)
    return Record(chrom, first, last, value)
end

function Base.convert(::Type{Vector{String}}, record::Record) :: Vector{String}
    return String[record.chrom, string(record.first), string(record.last), string(record.value)]
end

function Record(data::String)
    return convert(Record, data)
end

function Base.convert(::Type{Record}, str::AbstractString)
    data = _splitLine(str)
    return convert(Record, data)
end

function chrom(record::Record)::String
    return record.chrom
end

function Base.first(record::Record)::Int
    return record.first
end

function Base.last(record::Record)::Int
    return record.last
end

function value(record::Record)::Real
    return record.value
end

## Internal helper functions.
function _splitLine(line::String) ::Vector{String}
    cells::Vector{String} = filter!(!isempty, split(line, r"\s"))
end

function _convertCells(cells::Vector{String})
    length(cells) == 4 || error("Poor formatting:", cells)
    return cells[1], parse(Int, cells[2]), parse(Int, cells[3]), parse(Float64, cells[4]) #TODO: parse cell 4 as a generic Real.
end
