# Malformed Data

In really large and messy datasets, you may just want to skip the malformed rows

```jldoctest
julia> using uCSV, DataFrames, Test

julia> s =
       """
       1
       1,2
       """;

julia> e = @test_throws ErrorException DataFrame(uCSV.read(IOBuffer(s)))
Test Passed
      Thrown: ErrorException

julia> @test e.value.msg ==
       """
       Parsed 2 fields on row 2. Expected 1.
       line:
       1,2
       Possible fixes may include:
         1. including 2 in the `skiprows` argument
         2. setting `skipmalformed=true`
         3. if this line is a comment, setting the `comment` argument
         4. if fields are quoted, setting the `quotes` argument
         5. if special characters are escaped, setting the `escape` argument
         6. fixing the malformed line in the source or file before invoking `uCSV.read`
       """
Test Passed

julia> DataFrame(uCSV.read(IOBuffer(s), skipmalformed=true))
┌ Warning: Parsed 2 fields on row 2. Expected 1. Skipping...
└ @ uCSV ~/.julia/dev/uCSV/src/helperfunctions.jl:46
1×1 DataFrames.DataFrame
│ Row │ x1    │
│     │ Int64 │
├─────┼───────┤
│ 1   │ 1     │

```
