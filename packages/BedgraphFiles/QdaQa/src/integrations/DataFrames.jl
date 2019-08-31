@debug "BedgraphFiles loading DataFrames integration."

function Base.convert(::Type{Bedgraph.Record}, row::DataFrames.DataFrameRow) :: Bedgraph.Record
    return Bedgraph.Record(row[1], row[2], row[3], row[4]) # Note: using index to allow flexible column names.
end

function Base.convert(::Type{Vector{Bedgraph.Record}}, df::DataFrames.DataFrame) :: Vector{Bedgraph.Record}

    records = Vector{Bedgraph.Record}(undef, size(df)[1])

    for (i, row) in enumerate(eachrow(df))
        records[i] = convert(Bedgraph.Record, row)
    end

    return records
end
