include("../src/TableSchema.jl")
using TableSchema

# Either import the functions, or use TableSchema.read(<Table>) in the code
import TableSchema: read, is_valid, validate

import DelimitedFiles: readdlm

t = Table()

s = Schema("../data/schema_invalid_empty.json")
if is_valid(s) == false; println("An invalid Schema was found"); end

s = Schema("../data/schema_valid_missing.json")
if is_valid(s); println("A valid Schema is ready"); end

t.schema = s
source = readdlm("../data/data_types.csv", ',')
tr = read(t, data=source) # 5x5 Array{Any,2}
println( "The length is ", length(tr[:,1]) ) # 5
println( "Sum of column 2 is ", sum([ row for row in tr[2] ]) ) # 51.0

if validate(t); println("The table is valid according to the Schema"); end

t2 = Table("../data/data_constraints.csv", s)
if validate(t2) == false; println("This other table is not valid"); end
for err in t2.errors
    println(string(err.field.name, " has (expected) error: ", err.message))
end
