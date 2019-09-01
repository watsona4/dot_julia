module FeatherFiles

using FeatherLib, IteratorInterfaceExtensions, TableTraits, TableTraitsUtils,
    DataValues, Arrow, FileIO, TableShowUtils
import IterableTables

export load, save, File, @format_str

include("missing-conversion.jl")

struct FeatherFile
    filename::String
end

function Base.show(io::IO, source::FeatherFile)
    TableShowUtils.printtable(io, getiterator(source), "Feather file")
end

function Base.show(io::IO, ::MIME"text/html", source::FeatherFile)
    TableShowUtils.printHTMLtable(io, getiterator(source))
end

Base.Multimedia.showable(::MIME"text/html", source::FeatherFile) = true

function Base.show(io::IO, ::MIME"application/vnd.dataresource+json", source::FeatherFile)
    TableShowUtils.printdataresource(io, getiterator(source))
end

Base.Multimedia.showable(::MIME"application/vnd.dataresource+json", source::FeatherFile) = true

function fileio_load(f::FileIO.File{FileIO.format"Feather"})
    return FeatherFile(f.filename)
end

IteratorInterfaceExtensions.isiterable(x::FeatherFile) = true
TableTraits.isiterabletable(x::FeatherFile) = true
TableTraits.supports_get_columns_view(x::FeatherFile) = true
TableTraits.supports_get_columns_copy_using_missing(x::FeatherFile) = true

function IteratorInterfaceExtensions.getiterator(file::FeatherFile)
    rs = featherread(file.filename)

    for i=1:length(rs.columns)
        col_eltype = eltype(rs.columns[i])
        if isa(col_eltype, Union) && col_eltype.b <: Missing
            T = DataValueArrowVector{col_eltype.a,typeof(rs.columns[i])}
            rs.columns[i] = T(rs.columns[i])
        end
    end

    it = create_tableiterator(rs.columns, rs.names)

    return it
end

function TableTraits.get_columns_view(file::FeatherFile)
    rs = featherread(file.filename)

    for i=1:length(rs.columns)
        col_eltype = eltype(rs.columns[i])
        if isa(col_eltype, Union) && col_eltype.b <: Missing
            T = DataValueArrowVector{col_eltype.a,typeof(rs.columns[i])}
            rs.columns[i] = T(rs.columns[i])
        end
    end

    T = eval(:(@NT($(Symbol.(rs.names)...)))){typeof.(rs.columns)...}

    return T(rs.columns...)
end

function TableTraits.get_columns_copy_using_missing(file::FeatherFile)
     rs = featherread(file.filename)
     return NamedTuple{(Symbol.(rs.names)...,)}(((convert(Vector{eltype(c)}, c) for c in rs.columns)...,))
end

function fileio_save(f::FileIO.File{FileIO.format"Feather"}, data)
    isiterabletable(data) || error("Can't write this data to a Feather file.")

    columns, colnames = create_columns_from_iterabletable(data)

    columns = Any[c for c in columns]

    for i=1:length(columns)
        if eltype(columns[i]) <: DataValue
            T = MissingDataValueVector{eltype(eltype(columns[i])),typeof(columns[i])}
            columns[i] = T(columns[i])
        end
    end

    featherwrite(f.filename, columns, colnames)
end

end # module
