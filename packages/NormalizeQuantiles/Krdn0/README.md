Linux: [![Build Status](https://travis-ci.org/oheil/NormalizeQuantiles.jl.svg?branch=master)](https://travis-ci.org/oheil/NormalizeQuantiles.jl)
Windows: [![Build status](https://ci.appveyor.com/api/projects/status/github/oheil/normalizequantiles.jl?branch=master&svg=true)](https://ci.appveyor.com/project/oheil/normalizequantiles-jl/branch/master)

[![Project Status: Active – The project has reached a stable, usable state and is being actively developed.](http://www.repostatus.org/badges/latest/active.svg)](http://www.repostatus.org/#active)
[![Coverage Status](https://coveralls.io/repos/github/oheil/NormalizeQuantiles.jl/badge.svg?branch=master)](https://coveralls.io/github/oheil/NormalizeQuantiles.jl?branch=master)

# NormalizeQuantiles

For julia 0.4, 0.5, 0.6 see: https://github.com/oheil/NormalizeQuantiles.jl/tree/backport-0.6

Package NormalizeQuantiles implements quantile normalization

```julia
qn = normalizeQuantiles(array);
```

and provides a function to calculate sample ranks

```julia
(r,m) = sampleRanks(array);
```

of a given vector or matrix.

**References**

* Amaratunga, D.; Cabrera, J. (2001). "Analysis of Data from Viral DNA Microchips". Journal of the American Statistical Association. 96 (456): 1161. [doi:10.1198/016214501753381814](https://doi.org/10.1198/016214501753381814)
* Bolstad, B. M.; Irizarry, R. A.; Astrand, M.; Speed, T. P. (2003). "A comparison of normalization methods for high density oligonucleotide array data based on variance and bias". Bioinformatics. 19 (2): 185–193. [doi:10.1093/bioinformatics/19.2.185](https://doi.org/10.1093/bioinformatics/19.2.185) [PMID 12538238](https://www.ncbi.nlm.nih.gov/pubmed/12538238)
* Wikipedia contributors. (2018, June 12). Quantile normalization. In Wikipedia, The Free Encyclopedia. Retrieved 11:54, August 3, 2018, from [https://en.wikipedia.org/w/index.php?title=Quantile_normalization](https://en.wikipedia.org/w/index.php?title=Quantile_normalization)

**Table of Contents**

* [Dependencies](#dependencies)
* [Remarks](#remarks)
* [Usage examples `normalizeQuantiles`](#usage-examples-normalizequantiles)
  * [General usage](#general-usage)
  * [Missing Values](#missing-values)
  * [SharedArray and multicore usage examples](#sharedarray-and-multicore-usage-examples)
* [Behaviour of function `normalizeQuantiles`](#behaviour-of-function-normalizequantiles)
* [Data prerequisites](#data-prerequisites)
* [Remarks on data with missing values](#remarks-on-data-with-missing-values)
* [List of all exported definitions for `normalizeQuantiles`](#list-of-all-exported-definitions-for-normalizequantiles)
* [Usage examples `sampleRanks`](#usage-examples-sampleranks)
* [List of all exported definitions for `sampleRanks`](#list-of-all-exported-definitions-for-sampleranks)

## Dependencies

#### Julia versions

* Julia 0.7 or above

#### Third party packages

* none

#### Standard Library packages

* [Distributed](https://docs.julialang.org/en/v1/stdlib/Distributed/)
* [SharedArrays](https://docs.julialang.org/en/v1/stdlib/SharedArrays/)
* [Random](https://docs.julialang.org/en/v1/stdlib/Random/)
* [Statistics](https://docs.julialang.org/en/v1/stdlib/Statistics/)

## Remarks

* for julia 0.4, 0.5, 0.6 see: https://github.com/oheil/NormalizeQuantiles.jl/tree/backport-0.6
* Code examples and output on this page have been used on and copied from the julia 0.7 [REPL](https://docs.julialang.org/en/latest/manual/interacting-with-julia/)
* Last commit with julia 0.3 support: [Jan 20, 2017, eb97d24ff77d470d0d121fabf83d59979ad0db36](https://github.com/oheil/NormalizeQuantiles.jl/tree/eb97d24ff77d470d0d121fabf83d59979ad0db36)
  * git checkout eb97d24ff77d470d0d121fabf83d59979ad0db36

## Usage examples `normalizeQuantiles`

#### General usage
 
```julia
Pkg.add("NormalizeQuantiles");
using NormalizeQuantiles;
```

The following `array` is interpreted as a matrix with 4 rows and 3 columns:

```julia
array = [ 3.0 2.0 1.0 ; 4.0 5.0 6.0 ; 9.0 7.0 8.0 ; 5.0 2.0 8.0 ];
qn = normalizeQuantiles(array)
```
```
	julia> qn
	4×3 Array{Float64,2}:
	 2.0  3.0  2.0
	 4.0  6.0  4.0
	 8.0  8.0  7.0
	 6.0  3.0  7.0
```

The columns in `qn` are now quantile normalized to each other.

The input array must not have dimension larger than 2.

Return type of function normalizeQuantiles is always Array{Float64,2}

#### Missing Values

If your data contain some missing values like `NaN` (Not a Number) or something else, they will be changed to `NaN`:

```julia
array = [ NaN 2.0 1.0 ; 4.0 "empty" 6.0 ; 9.0 7.0 8.0 ; 5.0 2.0 8.0 ];
```
```
	julia> array
	4×3 Array{Any,2}:
	 NaN    2.0       1.0
	4.0   "empty"  6.0
	9.0  7.0       8.0
	5.0  2.0       8.0
```
```julia
qn = normalizeQuantiles(array)
```
```
	julia> qn
	4×3 Array{Float64,2}:
	 NaN      3.25  1.5
	   5.0  NaN     5.0
	   8.0    8.0   6.5
	   5.0    3.25  6.5
```

NaN is of type Float64, so there is nothing similar for Int types.

```
	julia> typeof(NaN)
	Float64
```

You can convert the result to `Array{Union{Missing, Float64},2}` with:

```julia
qnMissing = convert(Array{Union{Missing,Float64}},qn)
```
```
	julia> qnMissing
	4×3 Array{Union{Missing, Float64},2}:
	 NaN      3.25  1.5
	   5.0  NaN     5.0
	   8.0    8.0   6.5
	   5.0    3.25  6.5
```
```julia
qnMissing[isnan.(qnMissing)] = missing;
```
```
	julia> qnMissing
	4×3 Array{Union{Missing, Float64},2}:
	  missing  3.25      1.5
	 5.0        missing  5.0
	 8.0       8.0       6.5
	 5.0       3.25      6.5
```

#### SharedArray and multicore usage examples

> Remark: restart julia now. `addprocs()` must be called before `using NormalizeQuantiles;`.

To use multiple cores on a single machine you can use the standard packages `Distributed` and `SharedArrays`:

```julia
using Distributed
addprocs();
@everywhere using SharedArrays
@everywhere using NormalizeQuantiles

sa = SharedArray{Float64}([ 3.0 2.0 1.0 ; 4.0 5.0 6.0 ; 9.0 7.0 8.0 ; 5.0 2.0 8.0 ])
```
```
	julia> sa
	4×3 SharedArray{Float64,2}:
	 3.0  2.0  1.0
	 4.0  5.0  6.0
	 9.0  7.0  8.0
	 5.0  2.0  8.0
```
```julia
qn = normalizeQuantiles(sa)
```
```
	julia> qn
	4×3 Array{Float64,2}:
	 2.0  3.0  2.0
	 4.0  6.0  4.0
	 8.0  8.0  7.0
	 6.0  3.0  7.0
```

> Remark: restart julia again.

For small data sets using `Distributed` and `SharedArrays` decreases performance:

```julia
using NormalizeQuantiles
la = randn((100,100));
normalizeQuantiles(la); @time normalizeQuantiles(la);
```
```
	julia> @time normalizeQuantiles(la);
	  0.003178 seconds (8.35 k allocations: 2.813 MiB)
```

> Remark: restart julia.

```julia
using Distributed
addprocs();
@everywhere using SharedArrays
@everywhere using NormalizeQuantiles
sa = SharedArray{Float64}( randn((100,100)) );
normalizeQuantiles(sa); @time normalizeQuantiles(sa);
```
```
	julia> @time normalizeQuantiles(sa);
	  0.013014 seconds (12.10 k allocations: 432.146 KiB)
```

> Remark: restart julia.

For larger data sets performance increases with multicore processors:

```julia
using NormalizeQuantiles
la = randn((1000,10000));
normalizeQuantiles(la); @time normalizeQuantiles(la);
```
```
	julia> @time normalizeQuantiles(la);
	  2.959431 seconds (784.18 k allocations: 2.281 GiB, 12.13% gc time)
```

> Remark: restart julia.

```julia
using Distributed
addprocs();
@everywhere using SharedArrays
@everywhere using NormalizeQuantiles
la = randn((1000,10000));
sa = SharedArray{Float64}(la);
normalizeQuantiles(sa); @time normalizeQuantiles(sa);
```
```
	julia> @time normalizeQuantiles(sa);
	  1.030016 seconds (83.85 k allocations: 80.754 MiB, 5.77% gc time)
```
Using non-SharedArrays in a multicore setup is slowest:
```
	julia> normalizeQuantiles(la); @time normalizeQuantiles(la);
	  5.776685 seconds (294.06 k allocations: 92.532 MiB, 0.28% gc time)
```

## Behaviour of function `normalizeQuantiles`

After quantile normalization the sets of values of each column have the same statistical properties.
This is quantile normalization without a reference column.

The function `normalizeQuantiles` expects an array with dimension <= 2 and always returns a matrix of equal size as the input matrix and of type `Array{Float64,2}`.

`NaN` values of type `Float64` and any other non-numbers, like strings, are treated as random missing values and the result value will be `NaN`. See "Remarks on data with missing values" below.

## Data prerequisites

To use quantile normalization your data should have the following properties:

* the distribution of values in each column should be similar
* number of values for each column should be large
* number of missing values in the data should be small and of random nature

## Remarks on data with missing values

Currently there seems to be no general agreement on how to deal with missing values during quantile normalization. Here we put any given missing value back into the sorted column at the original position before calculating the mean of the rows.

## List of all exported definitions for `normalizeQuantiles`

| | normalizeQuantiles |
| -----------------------: | ----------------------- | 
| **Definition:** | `Array{Float64,2} function normalizeQuantiles(matrix::AbstractArray)` |
| Input type: | `matrix::AbstractArray` |
| Return type: | `Array{Float64,2}` |


## Usage examples `sampleRanks`

`sampleRanks` of a given vector calculates for each element the rank, which is the position of the element in the sorted vector.

```julia
using NormalizeQuantiles
a = [ 5.0 2.0 4.0 3.0 1.0 ];
(r,m) = sampleRanks(a);   # here only return value r is relevant, for m see below
r
```
```
	julia> r
	5-element Array{Union{Missing, Int64},1}:
	 5
	 2
	 4
	 3
	 1
```

If you provide a matrix like

```julia
array = [ 1.0 2.0 3.0 ; 4.0 5.0 6.0 ; 7.0 8.0 9.0 ; 10.0 11.0 12.0 ]
```
```
	julia> array
	4×3 Array{Float64,2}:
	  1.0   2.0   3.0
	  4.0   5.0   6.0
	  7.0   8.0   9.0
	 10.0  11.0  12.0
```

ranks are calculated column wise, or in other words, array is treated as `array[:]`:
```julia
(r,m) = sampleRanks(array);
r
```
```
	julia> r
	12-element Array{Union{Missing, Int64},1}:
	  1
	  4
	  7
	 10
	  2
	  5
	  8
	 11
	  3
	  6
	  9
	 12
```

There are three optional keyword parameters `tiesMethod`, `naIncreasesRank` and `resultMatrix`:

```julia
(r,m) = sampleRanks(a,tiesMethod=tmMin,naIncreasesRank=false,resultMatrix=true);
(r,m) = sampleRanks(a,resultMatrix=true);
```

Equal values in the vector are called ties. There are several methods available on how to treat ties:
* tmMin : the smallest rank for all ties (default)
* tmMax : the largest rank
* tmOrder : increasing ranks
* tmReverse : decreasing ranks
* tmRandom : the ranks are randomly distributed
* tmAverage : the average rounded to the next integer

These methods are defined and exported as
	
```julia
	@enum qnTiesMethods tmMin tmMax tmOrder tmReverse tmRandom tmAverage
```

Internally ties have increasing ranks. On these the chosen method is applied.
	
Examples:

```julia
a = [ 7.0 2.0 4.0 2.0 1.0 ];
(r,m) = sampleRanks(a); #which is the same as (r,m)=sampleRanks(a,tiesMethod=tmMin)
r
```
```
	julia> r
	5-element Array{Union{Missing, Int64},1}:
	 4
	 2
	 3
	 2
	 1
```
```julia
(r,m) = sampleRanks(a,tiesMethod=tmMax);
r
```
```
	julia> r
	5-element Array{Union{Missing, Int64},1}:
	 5
	 3
	 4
	 3
	 1
```
```julia
(r,m) = sampleRanks(a,tiesMethod=tmReverse);
r
```
```
	julia> r
	5-element Array{Union{Missing, Int64},1}:
	 5
	 3
	 4
	 2
	 1
```

One or more missing values in the vector are never equal and remain on there position after sorting. The rank of each missing value is always missing::Missing. The default is that a missing value does not increase the rank for successive values. Giving true keyword parameter `naIncreasesRank` changes that behavior to increasing the rank by 1 for successive values:

```julia
a = [ 7.0 2.0 4.0 2.0 1.0 ];
a[1] = NaN;
(r,m) = sampleRanks(a);
r
```
```
	julia> r
	5-element Array{Union{Missing, Int64},1}:
	  missing
	 2
	 3
	 2
	 1
```
```julia
(r,m) = sampleRanks(a,naIncreasesRank=true);
r
```
```
	julia> r
	5-element Array{Union{Missing, Int64},1}:
	  missing
	 3
	 4
	 3
	 2
```

The keyword parameter `resultMatrix` lets you generate a dictionary of rank indices to allow direct access to all values with a given rank. For large vectors this may have a large memory consumption therefor the default is to return an empty dictionary of type `Dict{Int64,Array{Int64,N}}`:

```julia
a = [ 7.0 2.0 4.0 2.0 1.0 ];
(r,m) = sampleRanks(a,resultMatrix=true);
m
```
```
	julia> m
	Dict{Int64,Array{Int64,N} where N} with 4 entries:
	  4 => [1]
	  2 => [2,4]
	  3 => [3]
	  1 => [5]
```
```julia
haskey(m,2)   #does rank 2 exist?
```
```
	julia> haskey(m,2)
	true
```
```julia
a[m[2]]   #all values of rank 2
```
```
	julia> a[m[2]]
	2-element Array{Float64,1}:
	 2.0
	 2.0
```

## List of all exported definitions for `sampleRanks`

| | sampleRanks |
| -----------------------: | ----------------------- | 
| **Definition:** | `@enum qnTiesMethods tmMin tmMax tmOrder tmReverse tmRandom tmAverage` |
| Description: ||
| tmMin | the smallest rank for all ties |
| tmMax | the largest rank |
| tmOrder | increasing ranks |
| tmReverse | decreasing ranks |
| tmRandom | the ranks are randomly distributed |
| tmAverage | the average rounded to the next integer |

| | sampleRanks | |
| -----------------------: | ----------------------- | ----------------------- | 
| **Definition:** | `(Array{Union{Missing,Int},1},Dict{Int,Array{Int}}) sampleRanks(array::AbstractArray; tiesMethod::qnTiesMethods=tmMin, naIncreasesRank=false, resultMatrix=false)` | **keyword arguments** |
| Input type: | `array::AbstractArray` | data |
| Input type: | `tiesMethod::qnTiesMethods` | how to treat ties (default: `tmMin`) |
| Input type: | `naIncreasesRank::bool` | increase rank by one if NA (default: `false`) |
| Input type: | `resultMatrix::bool` | create rank dictionary (default: `false`) |
| Return type: | `(Array{Union{Missing,Int},1},Dict{Int,Array{Int}})` ||


