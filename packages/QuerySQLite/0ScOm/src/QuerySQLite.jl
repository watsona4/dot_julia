module QuerySQLite

import Base: !, &, |, ==, !=, coalesce, collect, eltype, getproperty, in,
isdone, isequal, isless, ismissing, iterate, IteratorSize, occursin, show,
showerror, startswith
using Base: Generator, NamedTuple, RefValue, SizeUnknown, tail
using Base.Meta: quot
import Base.Multimedia: showable
using DataValues: DataValue
import IteratorInterfaceExtensions: getiterator, isiterable
import MacroTools
using MacroTools: @capture
import QueryOperators
import SQLite
import SQLite: getvalue
using SQLite: columns, DB, execute!, generate_namedtuple, juliatype,
SQLITE_DONE, SQLITE_NULL, SQLITE_ROW, sqlite3_column_count, sqlite3_column_name,
sqlite3_column_type, sqlite3_step, sqlitevalue, Stmt, tables
using TableShowUtils: printdataresource, printHTMLtable, printtable
import TableTraits: isiterabletable

export Database

include("utilities.jl")
include("source.jl")
include("iterate.jl")
include("translate.jl")
include("library.jl")
include("QueryOperators.jl")
include("realize.jl")

end # module
