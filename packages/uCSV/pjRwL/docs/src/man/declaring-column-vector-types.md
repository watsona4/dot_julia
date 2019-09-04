# Declaring Column Vector Types

## CategoricalArrays & other column types

Declaring all columns should be parsed as `CategoricalVector`s
```jldoctest
julia> using uCSV, DataFrames, CategoricalArrays

julia> s =
       """
       a,b,c
       a,b,c
       a,b,c
       a,b,c
       """;

julia> eltype.(DataFrames.columns(DataFrame(uCSV.read(IOBuffer(s), coltypes=CategoricalVector))))
3-element Array{DataType,1}:
 CategoricalString{UInt32}
 CategoricalString{UInt32}
 CategoricalString{UInt32}

```

Declaring whether each column should be a `CategoricalVector` or not
```jldoctest
julia> using uCSV, DataFrames, CategoricalArrays

julia> s =
       """
       a,b,c
       a,b,c
       a,b,c
       a,b,c
       """;

julia> eltype.(DataFrames.columns(DataFrame(uCSV.read(IOBuffer(s), coltypes=fill(CategoricalVector, 3)))))
3-element Array{DataType,1}:
 CategoricalString{UInt32}
 CategoricalString{UInt32}
 CategoricalString{UInt32}

```

Declaring whether specific columns should be `CategoricalVector`s by index
```jldoctest
julia> using uCSV, DataFrames, CategoricalArrays

julia> s =
       """
       a,b,c
       a,b,c
       a,b,c
       a,b,c
       """;

julia> eltype.(DataFrames.columns(DataFrame(uCSV.read(IOBuffer(s), coltypes=Dict(3 => CategoricalVector)))))
3-element Array{DataType,1}:
 String                   
 String                   
 CategoricalString{UInt32}

```

Declaring whether specific columns should be `CategoricalVector`s by column name
```jldoctest
julia> using uCSV, DataFrames, CategoricalArrays

julia> s =
       """
       a,b,c
       a,b,c
       a,b,c
       a,b,c
       """;

julia> eltype.(DataFrames.columns(DataFrame(uCSV.read(IOBuffer(s), header=1, coltypes=Dict("a" => CategoricalVector)))))
3-element Array{DataType,1}:
 CategoricalString{UInt32}
 String                   
 String                   

```
