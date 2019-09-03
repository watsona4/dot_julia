using TableSchema
using Test
using Dates

import TableSchema: read, validate, infer, commit, save

import DelimitedFiles: readdlm

include("read.jl")
include("schema.jl")
include("validate.jl")
include("infer.jl")
include("edit.jl")
include("save.jl")
# include("changes.jl")
