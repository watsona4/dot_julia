function parsefields(line::AbstractString, delim, quotes, escape, trimwhitespace::Bool)
    fields = SubString{String}[]
    isquoted = falses(0)
    badbreak = false
    eol = lastindex(line)
    fieldstart = firstindex(line)
    # delimrange = search(line, delim, fieldstart)
    delimrange = something(findnext(isequal(delim), line, fieldstart), 0)
    delimstart, nextfieldstart = first(delimrange), nextind(line, last(delimrange))
    done = false
    while !done
        fieldend = delimstart == 0 ? eol : prevind(line, delimstart)
        f = SubString(line, fieldstart, fieldend)
        field, quoted, badbreak = checkfield(f, quotes, escape, trimwhitespace)
        if badbreak
            if delimstart < 1
                return fields, isquoted, badbreak
            else
                delimrange = something(findnext(isequal(delim), line, nextfieldstart), 0)
                # delimrange = search(line, delim, nextfieldstart)
                delimstart, nextfieldstart = first(delimrange), nextind(line, last(delimrange))
                continue
            end
        end
        push!(fields, field)
        push!(isquoted, quoted)
        if nextfieldstart <= fieldstart
            done = true
        else
            fieldstart = nextfieldstart
        end
        # delimrange = search(line, delim, fieldstart)
        delimrange = something(findnext(isequal(delim), line, fieldstart), 0)
        delimstart, nextfieldstart = first(delimrange), nextind(line, last(delimrange))
    end
    return fields, isquoted, badbreak
end

function parsefields(line::AbstractString, delim, quotes::Missing, escape::Missing, trimwhitespace::Bool)
    fields = split(line, delim)
    isquoted = falses(length(fields))
    if trimwhitespace
        for (i, f) in enumerate(fields)
            fields[i] = strip(fields[i])
        end
    end
    return fields, isquoted, false
end
