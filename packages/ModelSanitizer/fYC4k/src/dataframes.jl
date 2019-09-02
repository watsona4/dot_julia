import .DataFrames

function _sanitize!(df::T, data::Vector{Data}, elements::_DataElements; kwargs...)::T where T <: DataFrames.AbstractDataFrame
    zero!(df)
    return df
end

function zero!(df::T; kwargs...)::T where T <: DataFrames.AbstractDataFrame
    for column in names(df)
        df[:, column] = zero!(df[:, column])
    end
    return df
end

function _elements!(all_elements::Vector{Any}, df::DataFrames.AbstractDataFrame; kwargs...) where T
    # push!(all_elements, df)
    for column in names(df)
        _elements!(all_elements, df[column])
    end
    return all_elements
end
