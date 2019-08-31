function _bump(records::Vector{Record}, b::Int) :: Vector{Record}

    new_records = Vector{Record}(undef, length(records))

    for (i, record) in enumerate(records)
        new_record  = Record(record.chrom, record.first + b, record.last + b, record.value)
        new_records[i] = new_record
    end

    return new_records
end

_bumpForward(records::Vector{Record}) = _bump(records, 1)
_bumpBack(records::Vector{Record}) = _bump(records, -1)


function _range(record::Record; right_open=true) :: UnitRange{Int}

    pos_start = right_open ? record.first : record.first + 1
    pos_end = right_open ? record.last - 1 : record.last

    return pos_start : pos_end
end


function _range(records::Vector{Record}; right_open=true) :: UnitRange{Int}

    pos_start = _range(records[1], right_open=right_open)[1]
    pos_end = _range(records[end], right_open=right_open)[end]

    return  pos_start : pos_end
end


function Base.convert(::Type{Vector{Record}}, chroms::Vector{String}, firsts::Vector{Int}, lasts::Vector{Int}, values::Vector{T}) where {T<:Real}

    len_chroms = length(chroms)

    # Check that arrays are of equal length.
    len_chroms == length(firsts) && length(lasts) == length(values) && len_chroms == length(values) || error("Vectors are of unequal lengths: chroms=$(length(chroms)), firsts=$(length(firsts)), lasts=$(length(lasts)), values=$(length(values))")

    records = Vector{Record}(undef, len_chroms)

    for (i, chrom, first, last, value) in zip(1:len_chroms, chroms, firsts, lasts, values)
        records[i] = Record(chrom, first, last, value)
    end

    return records
end


function compress(chroms::Vector{String}, n::Vector{Int}, values::Vector{<:Real}; right_open = true, bump_back=true) :: Vector{Record}

    ranges = Vector{UnitRange{Int}}()
    compressed_values = Vector{Float64}()
    compressed_chroms = Vector{String}()

    range_start = 1
    push!(compressed_values, values[1])

    for (index, value ) in enumerate(values)
        if value != compressed_values[end]
            push!(ranges, n[range_start] : n[index - 1] )
            push!(compressed_values, value)
            push!(compressed_chroms, chroms[index])
            range_start = index
        end

        if index == length(values)
            push!(ranges, n[range_start] : n[index] )
            push!(compressed_values, value)
            push!(compressed_chroms, chroms[index])
        end
    end

    if right_open
        for (index, value) in enumerate(ranges)
            ranges[index] = first(value) : last(value) + 1
        end
    else
        for (index, value) in enumerate(ranges)
            ranges[index] = first(value) -1 : last(value)
        end
    end

    len = length(ranges)

    new_records = Vector{Record}(undef, len)

    for (index, chrom, range, value) in zip(1:len, compressed_chroms, ranges, compressed_values)
        new_records[index]  = Record(chrom, first(range), last(range), value)
    end

    return bump_back ? _bumpBack(new_records) : new_records

end

compress(chrom::String, n::Vector{Int}, values::Vector{T}; right_open = true, bump_back=true) where {T<:Real} = compress(fill(chrom, length(n)), n, values, right_open = right_open, bump_back = bump_back)


function expand(records::Vector{Record}; right_open=true, bump_forward=true)

    #TODO: ensure records are sorted with no overlap.

    if bump_forward
        records =  _bumpForward(records)
    end

    total_range =_range(records, right_open = right_open)

    values = Vector{Float64}(undef, length(total_range))
    chroms = Vector{String}(undef, length(total_range))

    for record in records
        values[indexin(_range(record, right_open = right_open), total_range)] .= record.value
        chroms[indexin(_range(record, right_open = right_open), total_range)] .= record.chrom
    end

    return collect(total_range), values, chroms
end

expand(chrom::String, firsts::Vector{Int}, lasts::Vector{Int}, values::Vector{T}; right_open=true, bump_forward=true) where {T<:Real} = expand( fill(chrom, length(firsts)), firsts, lasts, values, right_open=right_open, bump_forward=bump_forward)
expand(chroms::Vector{String}, firsts::Vector{Int}, lasts::Vector{Int}, values::Vector{T}; right_open=true, bump_forward=true) where {T<:Real} = expand( convert(Vector{Record}, chroms, firsts, lasts, values), right_open=right_open, bump_forward=bump_forward)
