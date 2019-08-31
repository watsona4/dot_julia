using BenchmarkTools
using CSVReader
using DataFrames
using Dates
using Random
using Test

const iris = "iris.csv"

function testiris(df)
    @test size(df) == (150, 6)
    @test names(df) == Symbol.(["id", "Sepal.Length", "Sepal.Width", "Petal.Length", "Petal.Width", "Species"])
    @test unique(df[:Species]) == ["setosa", "versicolor", "virginica"]
    @test [sum(df[i]) for i in 2:5] ≈ [876.5, 458.6, 563.7, 179.9]
end

function genperf(rows, nfloat, nstr, strsize, nqfloat, nqstr, qstrsize)
    filename = "perf_f$(nfloat)_qf$(nqfloat)_s$(nstr),$(strsize)_qs$(nqstr),$(qstrsize)_$(rows).csv"
    open(filename, "w") do f
        for i in 1:rows
            floats = rand(nfloat)
            qfloats = ['"' * string(rand()) * '"' for _ in 1:nqfloat]
            strs  = [randstring(strsize) for _ in 1:nstr]
            qstrs = ['"' * randstring(qstrsize) * '"' for _ in 1:nqstr]
            println(f, join(vcat(floats, qfloats, strs, qstrs), ","))
        end
    end
    println(Dates.now(), " generated ", filename)
    filename
end

@testset "CSVReader" begin

    # readers available for testing
    readers = [CSVReader.read_csv]

    for reader in readers
        # basic usage
        df = reader("iris.csv") 
        testiris(df)

        # specified parsers
        df = reader("iris.csv", parsers"i,f:4,s") 
        testiris(df)

        # without headers
        df = reader("iris2.csv"; headers = false) 
        names!(df, Symbol.(["id", "Sepal.Length", "Sepal.Width", "Petal.Length", "Petal.Width", "Species"]))
        testiris(df)

        # missing data (1st row ok)
        df = reader("missing1.csv") 
        @test sum(count(ismissing, df[c]) for c in 1:ncol(df)) == 5

        # missing  data (1st row contains missing, causing column to have type String)
        df = reader("missing2.csv") 
        @test sum(count(ismissing, df[c]) for c in 1:ncol(df)) == 3

        # missing  data (1st row contains missing, causing column to have type String)
        # but, this is corrected via parsers spec
        df = reader("missing2.csv", parsers"i:4")
        @test sum(count(ismissing, df[c]) for c in 1:ncol(df)) == 5
    end

    # Performance test - generate test files.
    perf_files = String[]
    try
        for rows in [10, 1000], nfloat = [3, 5], nstr = [3, 5]
            push!(perf_files, genperf(rows, nfloat, nstr, 10, 0, 0, 0))
        end
        for file in perf_files
            for reader in readers
                println(Dates.now(), " [$(reader)] performance testing $file")
                @btime $reader($file)
            end
        end
    finally
        println(Dates.now(), " cleaning up")
        rm.(perf_files)
    end
    
end
