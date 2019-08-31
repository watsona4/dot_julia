"""
    function readFASTA(filename::String)

Parse a FASTA formatted file.
"""
function readFASTA(filename::String)
    data = Dict()
    lines = open(filename) do f
        readlines(f)
    end
    key = ""
    val = ""
    for i = 1:length(lines)
        line = lines[i]
        if startswith(line, '>')
            key = match(r"([^>])+", line).match
        else
            val = string(val, line)
            if i == length(lines)
                data[key] = val
                continue
            end
            nextLine = lines[i+1]
            if startswith(nextLine, '>')
                data[key] = val
                key = ""
                val = ""
            end
        end
    end
    return data
end

"""
    function parse_substitution_matrix(filename::String)


Parse substitution matrices from file.
"""
function parse_substitution_matrix(filename::String)
    scores = Dict{Tuple{Char,Char},Int}()
    cols = Char[]
    open(filename) do io
        for line in eachline(io)
            line = chomp(line)
            if startswith(line, "#") || isempty(line)
                continue
            end
            if isempty(cols)
                for y in eachmatch(r"[A-Z*]", line)
                    push!(cols, convert(Char, first(y.match)))
                end
            else
                x = convert(Char, first(line))
                ss = collect(eachmatch(r"-?\d+", line))
                for (y, s) in zip(cols, ss)
                    scores[(x, y)] = parse(Int, s.match)
                end
            end
        end
    end
    return scores
end
