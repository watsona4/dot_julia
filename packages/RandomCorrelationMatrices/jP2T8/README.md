# RandomCorrelationMatrices

[![Build Status](https://travis-ci.org/IainNZ/RandomCorrelationMatrices.jl.svg?branch=master)](https://travis-ci.org/IainNZ/RandomCorrelationMatrices.jl)

Generate random correlation matrices, for some definition of random. Currently supports just one definition/method:

> Lewandowski, Daniel, Dorota Kurowicka, and Harry Joe. "Generating random correlation matrices based on vines and extended onion method." Journal of multivariate analysis 100.9 (2009): 1989-2001. [doi:10.1016/j.jmva.2009.04.008](http://dx.doi.org/10.1016/j.jmva.2009.04.008)

This package has two functions, `randcormatrix(d, η)` and `randcovmatrix(d, η, σ)` . `d` is the dimension, and `η` is a parameter that controls the distribution of the off-diagonal terms. `randcovmatrix` is used to generate a covariance matrix from the output of `randcormatrix`, where the standard deviation of each component is controlled by `σ`.

To get a feel for how to set `η`, consider the following output from `test/runtests.jl`, which shows some example matrices and the average range of off-diagonals:

```
η => 2
 1.00  0.07  0.59  0.78
 0.07  1.00  0.28 -0.03
 0.59  0.28  1.00  0.69
 0.78 -0.03  0.69  1.00
mean(ranges) => 0.9609607012737842
median(ranges) => 0.9522641114303307
η => 8
 1.00 -0.24  0.15  0.18
-0.24  1.00 -0.10 -0.06
 0.15 -0.10  1.00  0.02
 0.18 -0.06  0.02  1.00
mean(ranges) => 0.5846747844778034
median(ranges) => 0.5787807331445632
η => 32
 1.00 -0.06  0.08 -0.11
-0.06  1.00 -0.05  0.12
 0.08 -0.05  1.00 -0.14
-0.11  0.12 -0.14  1.00
mean(ranges) => 0.3094525766085337
median(ranges) => 0.3050648782864559
η => 128
 1.00  0.05 -0.00 -0.02
 0.05  1.00 -0.05  0.07
-0.00 -0.05  1.00  0.03
-0.02  0.07  0.03  1.00
mean(ranges) => 0.15721653854980638
median(ranges) => 0.15120529987720227
```

Pull requests welcome for additional methods of generating random correlation matrices that are described in the literature.
