[![Build Status](https://travis-ci.org/baggepinnen/LazyWAVFiles.jl.svg?branch=master)](https://travis-ci.org/baggepinnen/LazyWAVFiles.jl)
[![codecov](https://codecov.io/gh/baggepinnen/LazyWAVFiles.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/baggepinnen/LazyWAVFiles.jl)

# LazyWAVFiles
This package let's you treat a wav-file on disk as an `AbstractArray`. Access to the data is lazy, i.e., nothing is read from the file until the array is indexed into. You can also specify a folder containing many wav-files and treat them all as a single large array! This lets you work using files that are too large to fit in memory. Some examples
```julia
using LazyWAVFiles, WAV

# Create some files to work with
d   = mktempdir()
a,b = randn(Float32,10), randn(Float32,10)
WAV.wavwrite(a, joinpath(d,"f1.wav"), Fs=8000)
WAV.wavwrite(b, joinpath(d,"f2.wav"), Fs=8000)

# Indexing into the array loads data from disk
f1 = LazyWAVFile(joinpath(d,"f1.wav"))
f1[1]   == a[1]
f1[1:5] == a[1:5]
size(f1)

# We can create an array from all files in a folder
df = DistributedWAVFile(d)
df[1]    == a[1]        # Indexing works the same
df[1:12] == [a; b[1:2]] # We can even index over both arrays
df[:]    == [a;b]       # Or load all files as one long vector

size(df) # Other array functions are defined as well
length(df)

# To work using chunks of the entire distributed array, we can use Iterators.partition
julia> Iterators.partition(df, 2) |> collect
10-element Array{Array{Float32,1},1}:
 [0.44920132, -1.1176418]
 [-2.0420709, 0.11797007]
 [1.4723421, -0.32837275]
 [2.3656073, 0.4933495]   
 [-1.0910473, -0.18483315]
 [-0.5574947, -0.46916208]
 [0.27721304, -0.39077175]
 [-0.05172622, -0.715703]
 [0.5821298, 1.6757511]   
 [1.0726295, 0.23483518]
```
