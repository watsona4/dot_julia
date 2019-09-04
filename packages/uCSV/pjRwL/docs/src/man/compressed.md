# Reading Compressed Datasets

Using the [TranscodingStreams.jl](https://github.com/bicycle1885/TranscodingStreams.jl#codec-packages) ecosystem of packages is currently the recommended approach, although other methods should work as well
```jldoctest
julia> using uCSV, DataFrames, CodecZlib

julia> iris_file = joinpath(dirname(dirname(pathof(uCSV))), "test", "data", "iris.csv.gz");

julia> iris_io = GzipDecompressorStream(open(iris_file));

julia> DataFrame(uCSV.read(iris_io, header=1))[1:5, :Species]
5-element Array{String,1}:
 "Iris-setosa"
 "Iris-setosa"
 "Iris-setosa"
 "Iris-setosa"
 "Iris-setosa"

```
