# KronLinInv.jl

[![Build Status](https://travis-ci.com/inverseproblem/KronLinInv.jl.svg?branch=master)](https://travis-ci.com/inverseproblem/KronLinInv.jl)

Docs: https://inverseproblem.github.io/KronLinInv.jl/latest


Kronecker-product-based linear inversion of geophysical (or other kinds of) data under Gaussian and separability assumptions. 
The code computes the posterior mean model and the posterior covariance matrix (or subsets of it) in an efficient manner (parallel algorithm) taking into account 3-D correlations both in the model parameters and in the observed data.

If you use this code for research or else, please cite the related paper:
 
Andrea Zunino, Klaus Mosegaard,
**An efficient method to solve large linearizable inverse problems under Gaussian and separability assumptions**,
Computers & Geosciences, 2018
ISSN 0098-3004, <https://doi.org/10.1016/j.cageo.2018.09.005>.

## Authors
Andrea Zunino, 
Niels Bohr Institute
