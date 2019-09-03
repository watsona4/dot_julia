"""
TableSchema module
https://github.com/frictionlessdata/tableschema-jl
"""
module TableSchema

export Table
export Schema
export Field

export TableValidationException
export ConstraintError
export SchemaError

using Base.Iterators: filter
using Base.Iterators: Repeated, repeated

using JSON
using Dates

import HTTP: request
import DelimitedFiles: readdlm, writedlm

const DEFAULT_TYPE = "string"
const DEFAULT_FORMAT = "default"
const MAX_ROWS_INFER = 100

include("constraints.jl")
include("field.jl")
include("exceptions.jl")
include("schema.jl")
include("table.jl")
include("validators.jl")

end # module
