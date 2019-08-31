# ClusteringGA

[![Travis](https://travis-ci.org/sambitdash/ClusteringGA.jl.svg?branch=master)](https://travis-ci.org/sambitdash/ClusteringGA.jl)
[![Coveralls](https://coveralls.io/repos/github/sambitdash/ClusteringGA.jl/badge.svg?branch=master)](https://coveralls.io/github/sambitdash/ClusteringGA.jl?branch=master)

`Clustering Genetic Algorithm` is a method that uses a modification of `Genetic Algorithms` to estimate potential clusters in a dataset. This is particulaly useful, in cases where other parameters like estimated numbers of clusters(`k`) may not be known be known. The alogorithm maximizes the mean silhouettes of clustering to compute the clusters.

Being an evolutionary alogorithm, the algorithm depends on randomly generated populations and for large datasets can be computational intensive. 

```
function cga(objects, distances, population_size, generations)
```

Compute the clusters in the objects using `Clustering Genetic Algorithms`.

* `objects`: the vector of objects used for clustering
* `distances`: the matrix providing the pairwise distance between the objects
* `population_size`: populations utilized in computing the genetic algorithm (default `20*length(objects)`)
* `generations`: number of generations for which genetic algorithm has to run (default `50`)

Return
------
   
It returns a tuple of ``CGAData`` and ``CGAResult``.

```
struct CGAResult <: ClusteringResult
	  assignments::Vector{Int}    # element-to-cluster assignments (n)
    counts::Vector{Int}         # number of samples assigned to each cluster (k)
    found_gen::Int              # first generation where the elite was found
    total_gen::Int              # total generations the GA has been run
end

mutable struct CGAData{S, T<:Real}
		# to be used as an opaque object and normally not to be queried for values.
end
```
Methods like `count` can be used with `CGAResult` as this is derived from the `Clustering.ClusteringResult` abstract type. 

Reference
---------

1. Hruschka, Eduardo & Ebecken, Nelson. (2003). A genetic algorithm for cluster analysis. Intell. Data Anal.. 7. 15-25. 10.3233/IDA-2003-7103. 
