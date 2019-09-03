include("../src/TableSchema.jl")
using TableSchema

import HTTP: request
import DelimitedFiles: readdlm

# Either import the functions, or use TableSchema.read(<Table>) in the code
import TableSchema: read, is_valid, validate

REMOTE_URL = "https://raw.githubusercontent.com/frictionlessdata/tableschema-jl/master/data/data_simple.csv"

println( "Fetching remote data ..." )
t = Table()
req = request("GET", REMOTE_URL)
data = readdlm(req.body, ',')
tr = read(t, data=data, cast=false) # Array{Any,2}

column1 = tr[:,1]
println( "The length is ", length(column1) ) # 3
println( "Fun cities are ", join([ row for row in column1 ], ",") ) # london,paris,rome

println( "Fetching remote schema ..." )
s = Schema("https://raw.githubusercontent.com/frictionlessdata/tableschema-jl/master/data/schema_valid_simple.json")

if is_valid(s); println("A valid Schema is ready"); end

t.schema = s
if validate(t); println("The table is valid according to the Schema"); end

for err in t.errors
    println(string(err.field.name, " has error: ", err.message))
end
