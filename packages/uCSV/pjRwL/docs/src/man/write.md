# Writing Data

`uCSV.write` supports writing generic datasets as well as writing `DataFrames`

```jldoctest
julia> using uCSV, DataFrames, CodecZlib

julia> df = DataFrame(uCSV.read(GzipDecompressorStream(open(joinpath(dirname(dirname(pathof(uCSV))), "test", "data", "iris.csv.gz"))), header=1));

julia> first(df, 6)
6×6 DataFrames.DataFrame. Omitted printing of 1 columns
│ Row │ Id    │ SepalLengthCm │ SepalWidthCm │ PetalLengthCm │ PetalWidthCm │
│     │ Int64 │ Float64       │ Float64      │ Float64       │ Float64      │
├─────┼───────┼───────────────┼──────────────┼───────────────┼──────────────┤
│ 1   │ 1     │ 5.1           │ 3.5          │ 1.4           │ 0.2          │
│ 2   │ 2     │ 4.9           │ 3.0          │ 1.4           │ 0.2          │
│ 3   │ 3     │ 4.7           │ 3.2          │ 1.3           │ 0.2          │
│ 4   │ 4     │ 4.6           │ 3.1          │ 1.5           │ 0.2          │
│ 5   │ 5     │ 5.0           │ 3.6          │ 1.4           │ 0.2          │
│ 6   │ 6     │ 5.4           │ 3.9          │ 1.7           │ 0.4          │

julia> outpath = joinpath(dirname(dirname(pathof(uCSV))), "test", "temp.txt");

julia> uCSV.write(outpath, header = string.(names(df)), data = DataFrames.columns(df))

julia> for line in readlines(open(outpath))[1:5]
          println(line)
       end
Id,SepalLengthCm,SepalWidthCm,PetalLengthCm,PetalWidthCm,Species
1,5.1,3.5,1.4,0.2,Iris-setosa
2,4.9,3.0,1.4,0.2,Iris-setosa
3,4.7,3.2,1.3,0.2,Iris-setosa
4,4.6,3.1,1.5,0.2,Iris-setosa

julia> uCSV.write(outpath, df)

julia> for line in readlines(open(outpath))[1:5]
          println(line)
       end
Id,SepalLengthCm,SepalWidthCm,PetalLengthCm,PetalWidthCm,Species
1,5.1,3.5,1.4,0.2,Iris-setosa
2,4.9,3.0,1.4,0.2,Iris-setosa
3,4.7,3.2,1.3,0.2,Iris-setosa
4,4.6,3.1,1.5,0.2,Iris-setosa

```

Users can specify delimiters other than `','`
```jldoctest
julia> using uCSV, DataFrames, CodecZlib

julia> df = DataFrame(uCSV.read(GzipDecompressorStream(open(joinpath(dirname(dirname(pathof(uCSV))), "test", "data", "iris.csv.gz"))), header=1));

julia> outpath = joinpath(dirname(dirname(pathof(uCSV))), "test", "temp.txt");

julia> uCSV.write(outpath, df, delim='\t')

julia> for line in readlines(open(outpath))[1:5]
          println(line)
       end
Id	SepalLengthCm	SepalWidthCm	PetalLengthCm	PetalWidthCm	Species
1	5.1	3.5	1.4	0.2	Iris-setosa
2	4.9	3.0	1.4	0.2	Iris-setosa
3	4.7	3.2	1.3	0.2	Iris-setosa
4	4.6	3.1	1.5	0.2	Iris-setosa

```

Quotes can also be requested, and by default they apply only to `String` (and `Union{String, Missing}`) columns and the header
```jldoctest
julia> using uCSV, DataFrames, CodecZlib

julia> df = DataFrame(uCSV.read(GzipDecompressorStream(open(joinpath(dirname(dirname(pathof(uCSV))), "test", "data", "iris.csv.gz"))), header=1));

julia> outpath = joinpath(dirname(dirname(pathof(uCSV))), "test", "temp.txt");

julia> uCSV.write(outpath, df, quotes='"')

julia> for line in readlines(open(outpath))[1:5]
          println(line)
       end
"Id","SepalLengthCm","SepalWidthCm","PetalLengthCm","PetalWidthCm","Species"
1,5.1,3.5,1.4,0.2,"Iris-setosa"
2,4.9,3.0,1.4,0.2,"Iris-setosa"
3,4.7,3.2,1.3,0.2,"Iris-setosa"
4,4.6,3.1,1.5,0.2,"Iris-setosa"


julia> # columns that are Union{T, Missing} where T <: quotetypes also works
       df_with_missings = deepcopy(df);

julia> df_with_missings[6] = convert(Vector{Union{String, Missing}}, df_with_missings[6]);

julia> df_with_missings[6][2:3] .= missing;

julia> uCSV.write(outpath, df_with_missings, quotes='"')

julia> for line in readlines(open(outpath))[1:5]
          println(line)
       end
"Id","SepalLengthCm","SepalWidthCm","PetalLengthCm","PetalWidthCm","Species"
1,5.1,3.5,1.4,0.2,"Iris-setosa"
2,4.9,3.0,1.4,0.2,"missing"
3,4.7,3.2,1.3,0.2,"missing"
4,4.6,3.1,1.5,0.2,"Iris-setosa"

julia> # but not if the column is ONLY missings
       df_with_missings[6] = missings(size(df_with_missings, 1));

julia> uCSV.write(outpath, df_with_missings, quotes='"')

julia> for line in readlines(open(outpath))[1:5]
          println(line)
       end
"Id","SepalLengthCm","SepalWidthCm","PetalLengthCm","PetalWidthCm","Species"
1,5.1,3.5,1.4,0.2,missing
2,4.9,3.0,1.4,0.2,missing
3,4.7,3.2,1.3,0.2,missing
4,4.6,3.1,1.5,0.2,missing
```

To quote every field in the dataset or other custom rules, use the `quotetypes` argument
```jldoctest
julia> using uCSV, DataFrames, CodecZlib

julia> df = DataFrame(uCSV.read(GzipDecompressorStream(open(joinpath(dirname(dirname(pathof(uCSV))), "test", "data", "iris.csv.gz"))), header=1));

julia> outpath = joinpath(dirname(dirname(pathof(uCSV))), "test", "temp.txt");

julia> uCSV.write(outpath, df, quotes='"', quotetypes=Any)

julia> for line in readlines(open(outpath))[1:5]
          println(line)
       end
"Id","SepalLengthCm","SepalWidthCm","PetalLengthCm","PetalWidthCm","Species"
"1","5.1","3.5","1.4","0.2","Iris-setosa"
"2","4.9","3.0","1.4","0.2","Iris-setosa"
"3","4.7","3.2","1.3","0.2","Iris-setosa"
"4","4.6","3.1","1.5","0.2","Iris-setosa"

julia> uCSV.write(outpath, df, quotes='"', quotetypes=Real)

julia> for line in readlines(open(outpath))[1:5]
          println(line)
       end
"Id","SepalLengthCm","SepalWidthCm","PetalLengthCm","PetalWidthCm","Species"
"1","5.1","3.5","1.4","0.2",Iris-setosa
"2","4.9","3.0","1.4","0.2",Iris-setosa
"3","4.7","3.2","1.3","0.2",Iris-setosa
"4","4.6","3.1","1.5","0.2",Iris-setosa

```
