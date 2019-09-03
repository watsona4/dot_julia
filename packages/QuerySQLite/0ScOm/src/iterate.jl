struct SQLiteCursor{Row}
    statement::Stmt
    status::RefValue{Cint}
    cursor_row::RefValue{Int}
end

function eltype(::SQLiteCursor{Row}) where {Row}
    Row
end
function IteratorSize(::Type{<:SQLiteCursor})
    SizeUnknown()
end

function isdone(cursor::SQLiteCursor)
    status = cursor.status[]
    if status == SQLITE_DONE
        true
    elseif status == SQLITE_ROW
        false
    elseif sqliteerror(cursor.statement.db)
        false
    else
        error("Unknown SQLite cursor status")
    end
end

function getvalue(cursor::SQLiteCursor, column_number::Int, ::Type{Value}) where {Value}
    handle = cursor.statement.handle
    column_type = sqlite3_column_type(handle, column_number)
    if column_type == SQLITE_NULL
        Value()
    else
        julia_type = juliatype(column_type) # native SQLite Int, Float, and Text types
        sqlitevalue(
            if julia_type === Any
                if !isbitstype(Value)
                    Value
                else
                    julia_type
                end
            else
                julia_type
            end, handle, column_number)
    end
end

function iterate(cursor::SQLiteCursor{Row}) where {Row}
    if isdone(cursor)
        nothing
    else
        named_tuple = generate_namedtuple(Row, cursor)
        cursor.cursor_row[] = 1
        named_tuple, 1
    end
end

function iterate(cursor::SQLiteCursor{Row}, state) where {Row}
    if state != cursor.cursor_row[]
        error("State does not match SQLiteCursor model_row")
    else
        cursor.status[] = sqlite3_step(cursor.statement.handle)
        if isdone(cursor)
            nothing
        else
            named_tuple = generate_namedtuple(Row, cursor)
            cursor.cursor_row[] = state + 1
            named_tuple, state + 1
        end
    end
end

function isiterable(::SourceCode)
    true
end
function isiterabletable(::SourceCode)
    true
end
function collect(source::SourceCode)
    collect(getiterator(source))
end

function second((value_1, value_2))
    value_2
end

function name_and_type(handle, column_number, nullable = true, strict_types = true)
    Symbol(unsafe_string(sqlite3_column_name(handle, column_number))),
    if strict_types
        julia_type = juliatype(handle, column_number)
        if nullable
            DataValue{julia_type}
        else
            julia_type
        end
    else
        Any
    end
end

function getiterator(source_code::SourceCode)
    # TODO REVIEW
    statement = Stmt(source_code.source, text(source_code))
    # bind!(statement, values)
    status = execute!(statement)
    handle = statement.handle
    schema = ntuple(
        let handle = handle
            column_number -> name_and_type(handle, column_number)
        end,
        sqlite3_column_count(handle)
    )
    SQLiteCursor{NamedTuple{
        Tuple(map_unrolled(first, schema)),
        Tuple{map_unrolled(second, schema)...}
    }}(statement, Ref(status), Ref(0))
end

function show(stream::IO, source::SourceCode)
    printtable(stream, getiterator(source), "SQLite query result")
end

function showable(::MIME"text/html", source::SourceCode)
    true
end
function show(stream::IO, ::MIME"text/html", source::SourceCode)
    printHTMLtable(stream, getiterator(source))
end

function showable(::MIME"application/vnd.dataresource+json", source::SourceCode)
    true
end
function show(stream::IO, ::MIME"application/vnd.dataresource+json", source::SourceCode)
    printdataresource(stream, getiterator(source))
end
