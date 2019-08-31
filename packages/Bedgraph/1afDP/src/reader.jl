# Check if the record data is in the four column BED format.
function isLikeRecord(line::String) :: Bool
    return  occursin(r"^\s*\S*(?=[A-Za-z0-9])\S*\s+(\d+)\s+(\d+)\s+(\S*\d)\s*$", line) # Note: is like a record.
end

function isBrowser(line::String) :: Bool
    return  occursin(r"^browser", lowercase(line))
end

function isComment(line::String) :: Bool
    return occursin(r"^\s*(?:#|$)", line)
end


function seekNextRecord(io::IO) :: Nothing

    pos = position(io)
    initial = pos == 0 ? -1 : pos # Note: Allows for the fist line of headerless bedGraph file to be read.
    line = ""

    while !eof(io) && (!isLikeRecord(line) || pos == initial)
        pos = position(io)
        line = readline(io)
    end

    seek(io, pos)

    return nothing

end

# Note: all options are placed in a single line separated by spaces.
function readParameters(io::IO) :: String
    seekstart(io)

    pos = position(io)

    while !eof(io) && !isLikeRecord(line) # Note: regex is used to limit the search by exiting the loop when a line matches the bedGraph record format.
        line = readline(io)

        if contains(line, "type=bedGraph") # Note: the track type is REQUIRED, and must be bedGraph.
            return line
        end

    end
end

function readRecord(io::IO) :: Union{Nothing, Record}

    line = readline(io)

    if isLikeRecord(line)
        return Record(line)
    end

    return nothing
end

function readRecords(io::IO) :: Vector{Record}
    seekstart(io)
    seekNextRecord(io)

    records = Vector{Record}()

    while !eof(io)
        record = readRecord(io)
        if record != nothing
            push!(records, record)
        end
    end

    return records

end

function Base.read(io::IO, ::Type{Vector{Record}}) :: Vector{Record}
    return readRecords(io)
end
