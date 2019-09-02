# PathDistribution.jl

[![PathDistribution](http://pkg.julialang.org/badges/PathDistribution_0.5.svg)](http://pkg.julialang.org/?pkg=PathDistribution)
[![PathDistribution](http://pkg.julialang.org/badges/PathDistribution_0.6.svg)](http://pkg.julialang.org/?pkg=PathDistribution)
[![PathDistribution](http://pkg.julialang.org/badges/PathDistribution_0.7.svg)](http://pkg.julialang.org/?pkg=PathDistribution)


[![Build Status](https://travis-ci.org/chkwon/PathDistribution.jl.svg?branch=master)](https://travis-ci.org/chkwon/PathDistribution.jl)
[![Build status](https://ci.appveyor.com/api/projects/status/ft7mcyofj0g9mxr5?svg=true)](https://ci.appveyor.com/project/chkwon/pathdistribution-jl)
[![Coverage Status](https://coveralls.io/repos/chkwon/PathDistribution.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/chkwon/PathDistribution.jl?branch=master)


This Julia package implements the Monte Carlo path generation method to estimate the number of simple paths between a pair of nodes in a graph, proposed by Roberts and Kroese (2007).

* [Roberts, B., & Kroese, D. P. (2007). Estimating the Number of *s*-*t* Paths in a Graph. *Journal of Graph Algorithms and Applications*, 11(1), 195-214.](http://dx.doi.org/10.7155/jgaa.00142)

Extending the same idea, this package also estimate the path-length distribution. That is, we can estimate the number of paths whose length is no greater than a certain number. This idea was used in the following paper:

* [Sun, L., Karwan, M, & Kwon, C. Generalized Bounded Rationality and Robust Multi-Commodity Network Design.](http://www.chkwon.net/papers/sun_gbr.pdf)

This package can also be used to fully enumerate all paths.

# Installation

This package requires Julia version 0.4.

```julia
Pkg.add("PathDistribution")
```


# Basic Usage with an Adjacency Matrix
First import the package:
```julia
using PathDistribution
```

Suppose we have an adjacency matrix of the form:

```julia
adj_mtx = [ 0 1 1 1 0 1 1 1 ;
            1 0 0 0 1 1 1 0 ;
            1 0 0 1 1 1 1 1 ;
            1 0 1 0 1 1 1 1 ;
            0 1 1 1 0 1 0 0 ;
            1 1 1 1 1 0 1 1 ;
            1 1 1 1 0 1 0 1 ;
            1 0 1 1 0 1 1 0 ]
```
and the origin node is 1 the destination node is 8.

## Monte-Carlo Simulation

To estimate the total number of paths from the origin to the destination, we can do the following:
```julia
# N1: number of samples in the first stage (default=5000)
# N2: number of samples in the second stage (default=10000)
no_path_est = monte_carlo_path_number(1, 8, adj_mtx)
no_path_est = monte_carlo_path_number(1, 8, adj_mtx, N1, N2)
```

To estimate the path-length distribution:
```julia
samples = monte_carlo_path_sampling(1, size(adj_mtx,1), adj_mtx)
x_data_est, y_data_est = estimate_cumulative_count(samples)
```
where `x_data_est` and `y_data_est` are for estimating the cumulative count of paths by path length. That is,
`y_data_est[i]` is an estimate for the number of simple paths whose length is no greater than `x_data_est[i]` between the origin and destination nodes. Note that `y_data_est[end]` is the estimated number of total paths.

## Full Enumeration

This package can also enumerate all paths explicitly. (**CAUTION:** It may take "forever" to enumerate all paths for a large network.)
```julia
path_enums = path_enumeration(1, size(adj_mtx,1), adj_mtx)
x_data, y_data = actual_cumulative_count(path_enums)
```
You can access each enumerated path as follows:
```julia
for enum in path_enums
    println("Length = $(enum.length) : $(enum.path)")
end
println("The total number of paths is $(length(path_enums))")
```


## Results

One obtains results similar to the following:
```
The total number of paths:
- Full enumeration      : 397
- Monte Carlo estimation: 395.6732706634341
```



# Another Form

When you have the following form data:
```julia
data = [
 1   4  79.0 ;
 1   2  59.0 ;
 2   4  31.0 ;
 2   3  90.0 ;
 2   5   9.0 ;
 2   6  32.0 ;
 3   9  89.0 ;
 3   8  66.0 ;
 3   6  68.0 ;
 3   7  47.0 ;
 4   3  14.0 ;
 4   9  95.0 ;
 4   8  88.0 ;
 5   3  44.0 ;
 5   6  83.0 ;
 6   7  33.0 ;
 6   8  37.0 ;
 7  11  79.0 ;
 7  12  10.0 ;
 8   7  95.0 ;
 8  10   0.0 ;
 8  12  30.0 ;
 9  10   5.0 ;
 9  11  44.0 ;
10  13  79.0 ;
10  14  91.0 ;
11  14  53.0 ;
11  15  80.0 ;
11  13  56.0 ;
12  15  75.0 ;
12  14   1.0 ;
13  14  48.0 ;
14  15  25.0 ;
]

st = round(Int, data[:,1]) #first column of data
en = round(Int, data[:,2]) #second column of data
len = data[:,3] #third

# Double them for two-ways.
start_node = [st; en]
end_node = [en; st]
link_length = [len; len]

origin = 1
destination = 15
```

## Monte-Carlo Simulation

The similar tasks as above can be done as follows:
```julia
# Full Enumeration
path_enums = path_enumeration(origin, destination, start_node, end_node, link_length)
x_data, y_data = actual_cumulative_count(path_enums)

# Monte-Carlo estimation
N1 = 5000
N2 = 10000
samples = monte_carlo_path_sampling(origin, destination, start_node, end_node, link_length)
samples = monte_carlo_path_sampling(origin, destination, start_node, end_node, link_length, N1, N2)
x_data_est, y_data_est = estimate_cumulative_count(samples)

println("===== Another Example =====")
println("The total number of paths:")
println("- Full enumeration      : $(length(path_enums))")
println("- Monte Carlo estimation: $(y_data_est[end])")
```

## Results

Results would look like:
```
===== Another Example =====
The total number of paths:
- Full enumeration      : 9851
- Monte Carlo estimation: 9742.908561771697
```
