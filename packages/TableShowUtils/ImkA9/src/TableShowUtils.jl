module TableShowUtils

import JSON, DataValues
import Markdown, Dates

function printtable(io::IO, source, typename::AbstractString; force_unknown_rows=false)
    T = eltype(source)

    if force_unknown_rows
        rows = nothing
        data = Iterators.take(source, 10) |> collect
    elseif Base.IteratorSize(source) isa Union{Base.HasLength, Base.HasShape{1}}
        rows = length(source)
        data = Iterators.take(source, 10) |> collect
    else
        data_plus_one = Iterators.take(source, 11) |> collect
        if length(data_plus_one)<11
            rows = length(data_plus_one)
            data = data_plus_one
        else
            rows = nothing
            data = data_plus_one[1:10]
        end
    end

    cols = length(fieldnames(T))

    println(io, "$(rows===nothing ? "?" : rows)x$(cols) $typename")

    colnames = String.(fieldnames(eltype(source)))

    NAvalues = [r==0 ? false : DataValues.isna(data[r][c]) for r in 0:length(data), c in 1:cols]

    data = [r==0 ? colnames[c] : isa(data[r][c], AbstractString) ? data[r][c] : sprint(io->show(IOContext(io, :compact => true), data[r][c])) for r in 0:length(data), c in 1:cols]

    maxwidth = [maximum(length.(data[:,c])) for c in 1:cols]

    available_heigth, available_width = displaysize(io)
    available_width -=1

    shortened_rows = Set{Int}()

    while sum(maxwidth) + (size(data,2)-1) * 3 > available_width
        if size(data,2)==1
            for r in 1:size(data,1)
                if length(data[r,1])>available_width
                    data[r,1] = data[r,1][1:nextind(data[r,1], 0, available_width-2)] * "\""
                    push!(shortened_rows, r)
                end
            end
            maxwidth[1] = available_width
            break
        else
            data = data[:,1:end-1]

            maxwidth = [maximum(length.(data[:,c])) for c in 1:size(data,2)]
        end
    end

    for c in 1:size(data,2)
        print(io, rpad(colnames[c], maxwidth[c]))
        if c<size(data,2)
            print(io, " │ ")
        end
    end
    println(io)
    for c in 1:size(data,2)
        print(io, repeat("─", maxwidth[c]))
        if c<size(data,2)
            print(io, "─┼─")
        end
    end
    for r in 2:size(data,1)
        println(io)
        for c in 1:size(data,2)

            if r in shortened_rows
                print(io, data[r,c],)
                print(io, "…")
            else
                if NAvalues[r,c]
                    printstyled(io, rpad(data[r,c], maxwidth[c]), color=:light_black)
                else
                    print(io, rpad(data[r,c], maxwidth[c]))
                end
            end
            if c<size(data,2)
                print(io, " │ ")
            end
        end
    end

    if rows===nothing
        row_post_text = "more rows"
    elseif rows > size(data,1)-1
        extra_rows = rows - 10
        row_post_text = "$extra_rows more $(extra_rows==1 ? "row" : "rows")"
    else
        row_post_text = ""
    end

    if size(data,2)!=cols
        extra_cols = cols-size(data,2)
        col_post_text = "$extra_cols more $(extra_cols==1 ? "column" : "columns"): "
        col_post_text *= Base.join([colnames[cols-extra_cols+1:end]...], ", ")
    else
        col_post_text = ""
    end

    if !isempty(row_post_text) || !isempty(col_post_text)
        println(io)
        print(io,"... with ")
        if !isempty(row_post_text)
            print(io, row_post_text)
        end
        if !isempty(row_post_text) && !isempty(col_post_text)
            print(io, ", and ")
        end
        if !isempty(col_post_text)
            print(io, col_post_text)
        end
    end
end

function printHTMLtable(io, source; force_unknown_rows=false)
    colnames = String.(fieldnames(eltype(source)))

    max_elements = 10

    if force_unknown_rows
        rows = nothing
    elseif Base.IteratorSize(source) isa Union{Base.HasLength, Base.HasShape{1}}
        rows = length(source)
    else
        count_needed_plus_one =  Iterators.count(i->true, Iterators.take(source, max_elements+1))
        rows = count_needed_plus_one<max_elements+1 ? count_needed_plus_one : nothing
    end

    haslimit = get(io, :limit, true)

    # Header
    print(io, "<table>")
    print(io, "<thead>")
    print(io, "<tr>")
    for c in colnames
        print(io, "<th>")
        print(io, c)
        print(io, "</th>")
    end
    print(io, "</tr>")
    print(io, "</thead>")

    # Body
    print(io, "<tbody>")
    count = 0
    for r in Iterators.take(source, max_elements)
        count += 1
        print(io, "<tr>")
        for c in values(r)
            print(io, "<td>")
            Markdown.htmlesc(io, sprint(io->show(IOContext(io, :compact => true),c)))
            print(io, "</td>")
        end
        print(io, "</tr>")
    end

    if rows==nothing
        row_post_text = "... with more rows."
    elseif rows > max_elements
        extra_rows = rows - max_elements
        row_post_text = "... with $extra_rows more $(extra_rows==1 ? "row" : "rows")."
    else
        row_post_text = ""
    end

    if !isempty(row_post_text)
        print(io, "<tr>")
        for c in colnames
            print(io, "<td>&vellip;</td>")
        end
        print(io, "</tr>")
    end

    print(io, "</tbody>")

    print(io, "</table>")

    if !isempty(row_post_text)
        print(io, "<p>")
        Markdown.htmlesc(io, row_post_text)
        print(io, "</p>")
    end
end

Base.Multimedia.istextmime(::MIME{Symbol("application/vnd.dataresource+json")}) = true

julia_type_to_schema_type(::Type{T}) where {T} = "string"
julia_type_to_schema_type(::Type{T}) where {T<:AbstractFloat} = "number"
julia_type_to_schema_type(::Type{T}) where {T<:Integer} = "integer"
julia_type_to_schema_type(::Type{T}) where {T<:Bool} = "boolean"
julia_type_to_schema_type(::Type{T}) where {T<:Dates.Time} = "time"
julia_type_to_schema_type(::Type{T}) where {T<:Dates.Date} = "date"
julia_type_to_schema_type(::Type{T}) where {T<:Dates.DateTime} = "datetime"
julia_type_to_schema_type(::Type{T}) where {T<:AbstractString} = "string"
julia_type_to_schema_type(::Type{T}) where {S, T<:DataValues.DataValue{S}} = julia_type_to_schema_type(S)

own_json_formatter(io, x) = JSON.print(io, x)
own_json_formatter(io, x::DataValues.DataValue) = DataValues.isna(x) ? JSON.print(io,nothing) : own_json_formatter(io, x[])

function printdataresource(io::IO, source)
    if Base.IteratorEltype(source) isa Base.EltypeUnknown
        first_el = first(source)
        col_names = String.(propertynames(first_el))
        col_types = [fieldtype(typeof(first_el), i) for i=1:length(col_names)]
    else
        col_names = String.(fieldnames(eltype(source)))
        col_types = [fieldtype(eltype(source), i) for i=1:length(col_names)]
    end
    schema = Dict("fields" => [Dict("name"=>string(i[1]), "type"=>julia_type_to_schema_type(i[2])) for i in zip(col_names, col_types)])

    print(io, "{")
    JSON.print(io, "schema")
    print(io, ":")
    JSON.print(io,schema)
    print(io,",")
    JSON.print(io, "data")
    print(io, ":[")

    for (row_i, row) in enumerate(source)
        if row_i>1
            print(io, ",")
        end

        print(io, "{")
        for col in 1:length(col_names)
            if col>1
                print(io, ",")
            end
            JSON.print(io, col_names[col])
            print(io, ":")
            # TODO This is not type stable, should really unroll the loop in a generated function
            own_json_formatter(io, row[col])
        end
        print(io, "}")
    end

    print(io, "]}")
end

end # module
