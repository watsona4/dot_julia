struct SourceCode{Source}
    source::Source
    code::Expr
end

"""
    get_table_names(source)::Tuple{Symbol}

Get the names of the tables in `source`
"""
function get_table_names(source::DB)
    as_symbols(tables(source).name)
end
export get_table_names

"""
    get_column_names(source, table_name)::Tuple{Symbol}

Get column names of `table_name` in `source`
"""
function get_column_names(source::DB, table_name)
    as_symbols(columns(source, String(table_name)).name)
end
export get_column_names


"""
    struct Database{Source}

`source` must support [`get_table_names`](@ref) and [`get_column_names`](@ref).
"""
struct Database{Source}
    source::Source
end

function Database(filename::AbstractString)
    return Database(SQLite.DB(filename))
end

get_source(source_tables::Database) = getfield(source_tables, :source)

function getproperty(source_tables::Database, table_name::Symbol)
    SourceCode(get_source(source_tables),
        Expr(:call, getproperty, source_tables, table_name)
    )
end

struct SourceRow{Source}
    source::Source
    table_name::Symbol
end

struct SourceOtherRow{Source}
    source::Source
    table_name::Symbol
end

function pop_sources!(sources, something)
    something
end
function pop_sources!(sources, source_code::SourceCode)
    push!(sources, source_code.source)
    source_code.code
end

struct NotOneSourceException <: Exception
    sources::Set{Any}
end
function showerror(exception::NotOneSourceException)
    "Expected exactly one source; got ($(exceptions.sources...))"
end

function combine_sources(a_function, source_codes...)
    sources = Set(Any[])
    codes = partial_map(pop_sources!, sources, source_codes)
    if length(sources) != 1
        throw(NotOneSourceException(sources))
    else
        SourceCode(first(sources), Expr(:call, a_function, codes...))
    end
end
