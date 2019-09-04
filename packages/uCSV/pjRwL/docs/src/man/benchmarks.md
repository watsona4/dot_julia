# Benchmarks

Note these are not exhaustive, but they do cover various common formats and try to constrain outputs to a common format for evaluating on a pseudo-level playing-field. This does not necessarily reflect the strengths or weaknesses of the other packages relative to uCSV, it's simply to observe the relative times and memory usage required to perform equivalent tasks.

All runs are done *WITHOUT* warmups or precompiling. Reading CSV files in Julia is an interesting problem. A major strength of Julia is that it will compile functions on the first call, making all successive calls faster (often 3-4 orders of magnitude faster). But very rarely will users need to read the same file twice, making the precompiled runtimes for these functions a poor reflection of real-world use, and thus they are not shown.

## Read

### Setup

All data will be read into equivalent DataFrames
```julia
using uCSV, CSV, TextParse, CodecZlib, DataFrames, Base.Test
GDS = GzipDecompressorStream;

function textparse2DF(x)
    DataFrame(Any[x[1]...], Symbol.(x[2]))
end
```

### [Iris](https://github.com/cjprybol/uCSV.jl/blob/master/test/data/iris.csv.gz)
```julia
iris_file = joinpath(dirname(dirname(pathof(uCSV))), "test", "data", "iris.csv.gz");
@time df1 = DataFrame(uCSV.read(GDS(open(iris_file)), header=1));
@time df2 = CSV.read(GDS(open(iris_file)), types=Dict(6=>String));
@time df3 = textparse2DF(csvread(GDS(open(iris_file)), pooledstrings=false));
@test df1 == df2 == df3
```

```julia
julia> iris_file = joinpath(dirname(dirname(pathof(uCSV))), "test", "data", "iris.csv.gz");

julia> @time df1 = DataFrame(uCSV.read(GDS(open(iris_file)), header=1));
  2.883561 seconds (2.16 M allocations: 112.477 MiB, 1.57% gc time)

julia> @time df2 = CSV.read(GDS(open(iris_file)), types=Dict(6=>String));
  6.311389 seconds (4.18 M allocations: 206.229 MiB, 3.63% gc time)

julia> @time df3 = textparse2DF(csvread(GDS(open(iris_file)), pooledstrings=false));
  2.719340 seconds (1.76 M allocations: 95.649 MiB, 3.09% gc time)

julia> @test df1 == df2 == df3
Test Passed

```

### [0s-1s](https://github.com/cjprybol/uCSV.jl/blob/master/test/data/0s-1s.csv.gz)
```julia
ints_file = joinpath(dirname(dirname(pathof(uCSV))), "test", "data", "0s-1s.csv.gz");
@time df1 = DataFrame(uCSV.read(GDS(open(ints_file)), header=1));
@time df2 = CSV.read(GDS(open(ints_file)));
@time df3 = textparse2DF(csvread(GDS(open(ints_file))));
@test df1 == df2 == df3
```

```julia
julia> ints_file = joinpath(dirname(dirname(pathof(uCSV))), "test", "data", "0s-1s.csv.gz");

julia> @time df1 = DataFrame(uCSV.read(GDS(open(ints_file)), header=1));
  5.227549 seconds (13.26 M allocations: 673.321 MiB, 3.64% gc time)

julia> @time df2 = CSV.read(GDS(open(ints_file)));
 11.261905 seconds (10.23 M allocations: 364.527 MiB, 3.33% gc time)

julia> @time df3 = textparse2DF(csvread(GDS(open(ints_file))));
  2.629143 seconds (1.80 M allocations: 188.707 MiB, 3.60% gc time)

julia> @test df1 == df2 == df3
Test Passed

```

### [Flights](https://github.com/cjprybol/uCSV.jl/blob/master/test/data/2010_BSA_Carrier_PUF.csv.gz)
```julia
carrier_file = joinpath(dirname(dirname(pathof(uCSV))), "test", "data", "2010_BSA_Carrier_PUF.csv.gz");
@time df1 = DataFrame(uCSV.read(GDS(open(carrier_file)), header=1, typedetectrows=2, encodings=Dict("" => missing), types=Dict(3 =>  Union{String, Missing})));
@time df2 = CSV.read(GDS(open(carrier_file)), types=Dict(3 => Union{String, Missing}, 4 => String, 5 => String, 8 => String));
# I was unable to get TextParse.jl to read this file correctly
@time df3 = textparse2DF(csvread(GDS(open(carrier_file)), pooledstrings=false, type_detect_rows=228990, nastrings=[""]));
@test_broken df1 == df2 == df3
@test df1 == df2
```

```julia
julia> carrier_file = joinpath(dirname(dirname(pathof(uCSV))), "test", "data", "2010_BSA_Carrier_PUF.csv.gz");

julia> @time df1 = DataFrame(uCSV.read(GDS(open(carrier_file)), header=1, typedetectrows=2, encodings=Dict("" => missing), types=Dict(3 =>  Union{String, Missing})));
 30.019385 seconds (97.68 M allocations: 4.060 GiB, 34.44% gc time)

julia> @time df2 = CSV.read(GDS(open(carrier_file)), types=Dict(3 => Union{String, Missing}, 4 => String, 5 => String, 8 => String));
 12.599813 seconds (77.04 M allocations: 1.809 GiB, 27.03% gc time)

julia> # I was unable to get TextParse.jl to read this file correctly
       @time df3 = textparse2DF(csvread(GDS(open(carrier_file)), pooledstrings=false, type_detect_rows=228990, nastrings=[""]));
 14.742316 seconds (49.82 M allocations: 2.733 GiB, 38.07% gc time)

julia> @test_broken df1 == df2 == df3
Test Broken
Expression: df1 == df2 == df3


julia> @test df1 == df2
Test Passed

```

### [Human Genome Feature Format](https://github.com/cjprybol/uCSV.jl/blob/master/test/data/Homo_sapiens.GRCh38.90.gff3.gz)
```julia
genome_file = joinpath(dirname(dirname(pathof(uCSV))), "test", "data", "Homo_sapiens.GRCh38.90.gff3.gz");
@time df1 = DataFrame(uCSV.read(GDS(open(genome_file)), delim='\t', comment='#', types=Dict(1 => String)));
@time df2 = CSV.read(IOBuffer(join(filter(line -> !startswith(line, '#'), readlines(GDS(open(genome_file)))), '\n')), delim='\t', types=Dict(1 => String, 2 => String, 3 => String, 6 => String, 7 => String, 8 => String, 9 => String), header=[:x1, :x2, :x3, :x4, :x5, :x6, :x7, :x8, :x9]);
@test_broken df3 = textparse2DF(csvread(IOBuffer(join(filter(line -> !startswith(line, '#'), readlines(GDS(open(genome_file)))), '\n')), '\t', pooledstrings=false));
@test df1 == df2
```

```julia
julia> genome_file = joinpath(dirname(dirname(pathof(uCSV))), "test", "data", "Homo_sapiens.GRCh38.90.gff3.gz");

julia> @time df1 = DataFrame(uCSV.read(GDS(open(genome_file)), delim='\t', comment='#', types=Dict(1 => String)));
 28.335226 seconds (94.83 M allocations: 4.768 GiB, 41.27% gc time)

julia> @time df2 = CSV.read(IOBuffer(join(filter(line -> !startswith(line, '#'), readlines(GDS(open(genome_file)))), '\n')), delim='\t', types=Dict(1 => String, 2 => String, 3 => String, 6 => String, 7 => String, 8 => String, 9 => String), header=[:x1, :x2, :x3, :x4, :x5, :x6, :x7, :x8, :x9]);
 22.957273 seconds (86.07 M allocations: 3.899 GiB, 42.63% gc time)

julia> @test_broken df3 = textparse2DF(csvread(IOBuffer(join(filter(line -> !startswith(line, '#'), readlines(GDS(open(genome_file)))), '\n')), '\t', pooledstrings=false));

julia> @test df1 == df2
Test Passed

```

### [Country Indicators](https://github.com/cjprybol/uCSV.jl/blob/master/test/data/indicators.csv.gz)
```julia
indicators_file = joinpath(dirname(dirname(pathof(uCSV))), "test", "data", "indicators.csv.gz");
@time df1 = DataFrame(uCSV.read(GDS(open(indicators_file)), quotes='"'));
@time df2 = CSV.read(GDS(open(indicators_file)), header=[:x1, :x2, :x3, :x4, :x5, :x6], types=Dict(1 => String, 2 => String, 3 => String, 4 => String));
@time df3 = textparse2DF(csvread(GDS(open(indicators_file)), pooledstrings=false, header_exists=false, colnames=[:x1, :x2, :x3, :x4, :x5, :x6]));
# CSV.read & csvread both incorrectly parse the Float64s in the final column
@test_broken df1 == df2 == df3
@test eltype.(df1.columns) == eltype.(df2.columns) == eltype.(df3.columns)
```

```julia
julia> indicators_file = joinpath(dirname(dirname(pathof(uCSV))), "test", "data", "indicators.csv.gz");

julia> @time df1 = DataFrame(uCSV.read(GDS(open(indicators_file)), quotes='"'));
 38.058086 seconds (149.67 M allocations: 7.614 GiB, 47.15% gc time)

julia> @time df2 = CSV.read(GDS(open(indicators_file)), header=[:x1, :x2, :x3, :x4, :x5, :x6], types=Dict(1 => String, 2 => String, 3 => String, 4 => String));
 17.559485 seconds (55.74 M allocations: 1.922 GiB, 26.93% gc time)

julia> @time df3 = textparse2DF(csvread(GDS(open(indicators_file)), pooledstrings=false, header_exists=false, colnames=[:x1, :x2, :x3, :x4, :x5, :x6]));
 13.672462 seconds (13.38 M allocations: 1.384 GiB, 26.24% gc time)

julia> @test eltype.(df1.columns) == eltype.(df2.columns) == eltype.(df3.columns)
true

```

### [Yellow Taxi](https://s3.amazonaws.com/nyc-tlc/trip+data/yellow_tripdata_2015-01.csv)
```julia
taxi_file = joinpath(homedir(), "Downloads", "yellow_tripdata_2015-01.csv");
@time df1 = DataFrame(uCSV.read(taxi_file, header=1, typedetectrows=6, types=Dict(18=>Union{Float64, Missing}), encodings=Dict("" => missing)));
# CSV.read parses 6, 7, 10, and 11 incorrectly, again, all Float64 columns
@time df2 = CSV.read(taxi_file, types=eltype.(df1.columns));
# csvread
@time df3 = textparse2DF(csvread(taxi_file));
```

```julia
julia> @time df1 = DataFrame(uCSV.read(taxi_file, header=1, typedetectrows=6, types=Dict(18=>Union{Float64, Missing}), encodings=Dict("" => missing)));
224.209436 seconds (780.01 M allocations: 32.626 GiB, 33.88% gc time)

julia> @time df2 = CSV.read(taxi_file, types=eltype.(df1.columns));
112.266853 seconds (692.94 M allocations: 13.221 GiB, 72.15% gc time)

julia> @time df3 = textparse2DF(csvread(taxi_file));
 67.999334 seconds (28.69 M allocations: 3.790 GiB, 56.92% gc time)

```

## Write

If you're interested in seeing this, let me know by filing an issue or by running some comparisons yourself and opening a PR with the results!
