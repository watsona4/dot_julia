@code_instead (==) SourceCode Any
@code_instead (==) Any SourceCode
@code_instead (==) SourceCode SourceCode
@translate ::typeof(==) :(=)

@code_instead (!=) SourceCode Any
@code_instead (!=) Any SourceCode
@code_instead (!=) SourceCode SourceCode
@translate ::typeof(!=) Symbol("<>")

@code_instead (!) SourceCode
@translate ::typeof(!) :NOT

@code_instead (&) SourceCode Any
@code_instead (&) Any SourceCode
@code_instead (&) SourceCode SourceCode
@translate ::typeof(&) :AND

@code_instead (|) SourceCode Any
@code_instead (|) Any SourceCode
@code_instead (|) SourceCode SourceCode
@translate ::typeof(|) :OR

@code_instead coalesce SourceCode Vararg{Any}
@translate ::typeof(coalesce) :COALESCE

function get_column(source_row, column_name)
    SourceCode(source_row.source, Expr(:call, getproperty, source_row, column_name))
end
function model_row_dispatch(::typeof(getproperty), source_tables::Database, table_name; other = false, options...)
    source = get_source(source_tables)
    column_names = get_column_names(source, table_name)
    NamedTuple{column_names}(partial_map(
        get_column,
        if other
            SourceOtherRow(source, table_name)
        else
            SourceRow(source, table_name)
        end,
        column_names
    ))
end
function translate_dispatch(::typeof(getproperty), source_tables::Database, table_name; other = false, options...)
    if other
        translate(table_name)
    else
        SQLExpression(:FROM, translate(table_name))
    end
end
function translate_dispatch(::typeof(getproperty), source_row::SourceRow, column_name; options...)
    translate(column_name; options...)
end

function translate_dispatch(::typeof(getproperty), source_row::SourceOtherRow, column_name; options...)
    SQLExpression(:., source_row.table_name, translate(column_name; options...))
end

"""
    if_else(switch, yes, no)

`ifelse` that you can add methods to.

```jldoctest
julia> using QuerySQLite

julia> if_else(true, 1, 0)
1

julia> if_else(false, 1, 0)
0
```
"""
function if_else(switch, yes, no)
    ifelse(switch, yes, no)
end
export if_else

@code_instead if_else SourceCode Any Any
@code_instead if_else Any SourceCode Any
@code_instead if_else Any Any SourceCode
@code_instead if_else Any SourceCode SourceCode
@code_instead if_else SourceCode Any SourceCode
@code_instead if_else SourceCode SourceCode Any
@code_instead if_else SourceCode SourceCode SourceCode
@translate ::typeof(if_else) :IF

@code_instead in SourceCode Any
@code_instead in Any SourceCode
@code_instead in SourceCode SourceCode
@translate ::typeof(in) :IN

@code_instead isequal SourceCode Any
@code_instead isequal Any SourceCode
@code_instead isequal SourceCode SourceCode
@translate ::typeof(isequal) Symbol("IS NOT DISTINCT FROM")

@code_instead isless SourceCode Any
@code_instead isless Any SourceCode
@code_instead isless SourceCode SourceCode
@translate ::typeof(isless) :<

@code_instead ismissing SourceCode
@translate ::typeof(ismissing) Symbol("IS NULL")

@code_instead occursin AbstractString SourceCode
@code_instead occursin Regex SourceCode
translate_dispatch(::typeof(occursin), needle::AbstractString, haystack; options...) =
    SQLExpression(
        :LIKE,
        translate(haystack; options...),
        string('%', needle, '%')
    )
translate_dispatch(::typeof(occursin), needle::Regex, haystack; options...) =
    SQLExpression(
        :LIKE,
        translate(haystack; options...),
        replace(replace(needle.pattern, r"(?<!\\)\.\*" => "%"), r"(?<!\\)\." => "_")
    )
@translate ::typeof(occursin) :LIKE

@code_instead startswith SourceCode Any
@code_instead startswith Any SourceCode
@code_instead startswith SourceCode SourceCode


@code_instead secondary SourceCode
"""
A dummy function for marking a secondary table
"""
function secondary(something)
    something
end
translate_dispatch(::typeof(startswith), full, prefix::AbstractString; options...) =
    SQLExpression(
        :LIKE,
        translate(full),
        string(prefix, '%')
    )

translate_dispatch(::typeof(startswith), full, prefix::AbstractString; options...) =
    SQLExpression(
        :LIKE,
        translate(full),
        string(prefix, '%')
    )
