# CumulantsFeatures.jl


[![Build Status](https://travis-ci.org/ZKSI/CumulantsFeatures.jl.svg?branch=master)](https://travis-ci.org/ZKSI/CumulantsFeatures.jl)
[![Coverage Status](https://coveralls.io/repos/github/ZKSI/CumulantsFeatures.jl/badge.svg?branch=master)](https://coveralls.io/github/ZKSI/CumulantsFeatures.jl?branch=master)
[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.1468175.svg)](https://doi.org/10.5281/zenodo.1468175)

CumulantsFeatures.jl provides multivariate cumulants based algorithms used to select a features subset or detect an outlier subset out of realisations of multivariate data.
In both cases,the ordinary data subset is assumed to be modelled by the Gaussian multivariate distribution, while the outlier data subset is assumed to be modelled by the non-Gaussian multivariate distribution.
The algorithms handles `t` realisations of `n` variate data presented in the form of `t x n` matrix of Floats. In the case of features selection one has to compute multivariate cumulants first using
Cumulants.jl.

As of 24/09/2018 [@kdomino](https://github.com/kdomino) is the lead maintainer of this package.

## Installation

Within Julia, run

```julia
pkg> add CumulantsFeatures
```

to install the files. Julia 0.7 or later is required. Requires SymmetricTensors Cumulants and CumulantsUpdates modules.

## Features selection

Given the `Σ`- covariance matrix of data and `c` - the `N`-th cumulant's tensor
select `k` marginals with low `N`'th order dependencies by running:

```julia

julia> function cumfsel(Σ::SymmetricTensor{T,2}, c::SymmetricTensor{T, N}, f::String, k::Int = Σ.dats) where {T <: AbstractFloat, N}

```
To compute the covariance matrix and `N`-th cumulant's tensor use Cumulants.jl
`Σ.dats` is a size of the `Σ` matrix stored in the `SymmetricTensor` type, see SymmetricTensors.jl.
The `f` is the optimization function, `["hosvd", "norm", "mev"]` are supported. The "hosvd" uses the Higher Order Singular Value decomposition approximation of the higher order cumulant's tensor to extract information. While using "hosvd" we have the following family of methods. For `N=3` the Joint Skewness Band Selection (JSBS) - see X. Geng, K. Sun, L. Ji, H. Tang & Y. Zhao 'Joint Skewness and Its Application in Unsupervised Band Selection for Small Target Detection Sci Rep. vol.5 (2015) https://www.nature.com/articles/srep09915. For `N = 4` the Joint Kurtosis Features Selection (JKFS) - see K. Domino: 'The use of the Higher Order Singular Value Decomposition of the 4-cumulant's tensors in features selection and outlier detection', [arXiv:1804.00541] (https://arxiv.org/abs/1804.00541) (2018). For `N = 5` the Joint Hyper Kurtosis Features Selection (JHKFS). For application of HOSVD based methods see also P. Głomb, K. Domino, M. Romaszewski, M. Cholewa 'Band selection with Higher Order Multivariate Cumulants for small target detection in hyperspectral images', [arXiv:1808.03513] (https://arxiv.org/abs/1808.03513) (2018). The "norm" uses the norm of the higher order cumulant's tensor, this is a benchmark method for comparison. The "mev" uses only second order correlations, see: C. Sheffield, 'Selecting band combinations from multispectral data', Photogrammetric Engineering and Remote Sensing, vol. 51 (1985)

```julia

julia> srand(42);

julia> using Cumulants

julia> using SymmetricTensors

julia> x = rand(12,10);

julia> c = cumulants(x, 4);

julia> cumfsel(c[2], c[4], "hosvd")
10-element Array{Any,1}:
 (Bool[true, true, true, false, true, true, true, true, true, true], 27.2519, 4)        
 (Bool[true, true, false, false, true, true, true, true, true, true], 22.6659, 3)       
 (Bool[true, true, false, false, false, true, true, true, true, true], 18.1387, 5)      
 (Bool[false, true, false, false, false, true, true, true, true, true], 14.4492, 1)     
 (Bool[false, true, false, false, false, true, true, false, true, true], 11.2086, 8)    
 (Bool[false, true, false, false, false, true, true, false, true, false], 7.84083, 10)  
 (Bool[false, false, false, false, false, true, true, false, true, false], 5.15192, 2)  
 (Bool[false, false, false, false, false, false, true, false, true, false], 2.56748, 6)
 (Bool[false, false, false, false, false, false, true, false, false, false], 0.30936, 9)
 (Bool[false, false, false, false, false, false, false, false, false, false], 0.0, 7)  

```

Returns an Array of tuples `(ind::Array{Bool}, fval::Float64, i::Int)`. First tuple corresponds to the marginal with lowest `N`'th order dependencies with other marginals, while last tuple to the marginal with highest
`N`'th order dependencies. The `k`'th array gives an outcome after `k` steps. Here `ind` shows `k` marginals that yields lowest `N`'th order dependencies, `fval` the value of the target function at `k`'th step and `i` numerates the marginal removed at step `k`.

To limit number of steps (e.g. to `2`) run:

```julia

julia> cumfsel(Array(c[2]), Array(c[4]), "hosvd", 2)
2-element Array{Any,1}:
 (Bool[true, true, true, false, true, true, true, true, true, true], 27.2519, 4)
 (Bool[true, true, false, false, true, true, true, true, true, true], 22.6659, 3)

```

If running

```julia

julia> cumfsel(Σ::SymmetricTensor{T,2}, k::Int = Σ.dats)

```
The mev optimization function will be used.

## Detection

### RX detector

```julia

  rxdetect(X::Matrix{T}, α::Float64 = 0.99)

```

Takes data `X` in the form of matrix where first index correspond to realisations and
second to features (marginals). Using the RX (Reed-Xiaoli) Anomaly Detection returns the array of Bool that
correspond to outlier realisations. `α` is the sensitivity (threshold) parameter of the RX detector.


```julia
julia> srand(42);

julia> x = vcat(rand(8,2), 20*rand(2,2))
10×2 Array{Float64,2}:
  0.533183    0.956916
  0.454029    0.584284
  0.0176868   0.937466
  0.172933    0.160006
  0.958926    0.422956
  0.973566    0.602298
  0.30387     0.363458
  0.176909    0.383491
 11.8582      5.25618
 14.9036     10.059   

julia> rxdetect(x, 0.95)
10-element Array{Bool,1}:
 false
 false
 false
 false
 false
 false
 false
 false
  true
  true
```

### The HOSVD of the `4`'th cumulant

```julia

  function hosvdc4detect(X::Matrix{T}, β::Float64 = 4.1, r::Int = 3)

```


Takes data in the form of matrix where first index correspond to realisations and
second to features (marginals). Using the HOSVD of the `4`'th cumulant's tensor of data returns the array of `Bool` that correspond to outlier realisations. For the detector introduction see see K. Domino: 'The use of the Higher Order Singular Value Decomposition of the 4-cumulant's tensors in features selection and outlier detection', [arXiv:1804.00541] (https://arxiv.org/abs/1804.00541) (2018). The parameter `β` is the sensitivity parameter while `r` a
number of specific directions, data are projected onto.

```julia

julia> srand(42);

julia> x = vcat(rand(8,2), 20*rand(2,2))
10×2 Array{Float64,2}:
  0.533183    0.956916
  0.454029    0.584284
  0.0176868   0.937466
  0.172933    0.160006
  0.958926    0.422956
  0.973566    0.602298
  0.30387     0.363458
  0.176909    0.383491
 11.8582      5.25618
 14.9036     10.059

julia> rxdetect(x, 0.95)
10-element Array{Bool,1}:
 false
 false
 false
 false
 false
 false
 false
 false
  true
  true
```
## Data generation and tests

In folder tests there following Julia executable files.

### Features selection

 The executable file `jkfs_select.jl` generates multivariate data with non-Gaussian subset of marginals modelled by the t-Student copula. This file is parametrised by an integer being a number of degrees of freedom of the t-Student copula. Returns a `.jld2` file with data in `\jkfsdata_select` folder. Run `jkfs_data_analysis.jl` within, to achieve results of features selection given different methods.

### Outlier detection

 The executable file `jkfs_outliers.jl` generates multivariate data with non-Gaussian outliers subset of realisations modeled by the t-Student copula.
 This file is parametrised by an integer being a number of degrees of freedom of the t-Student copula. Returns a `.jld2` file with data in `\data_outliers` folder. Run `detect.jl` within to detect outliers and compare the "HOSVD" based method with the "RX" detector.

# Citing this work

This project was partially financed by the National Science Centre, Poland – project number 2014/15/B/ST6/05204.

While using this module, please cite K. Domino: 'The use of the Higher Order Singular Value Decomposition of the 4-cumulant's tensors in features selection and outlier detection', [arXiv:1804.00541] (https://arxiv.org/abs/1804.00541).
