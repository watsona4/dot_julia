# ApproximateBayesianComputing (ABC)

[![Build Status](https://travis-ci.org/eford/ApproximateBayesianComputing.jl.png)](https://travis-ci.org/eford/ApproximateBayesianComputing.jl)

[![](https://img.shields.io/badge/docs-stable-blue.svg)](https://eford.github.io/ApproximateBayesianComputing.jl/stable)
[![](https://img.shields.io/badge/docs-latest-blue.svg)](https://eford.github.io/ApproximateBayesianComputing.jl/latest)

This package implements basic algorithms fo Approximate Bayesian Computing (ABC) in Julia.  
Currently, it implements a single algorithm, ABC-PMC based on Beaumont et al. 2002 via abc_pmc_plan_type.

# To Do
* Write more realistic examples, before finalizing interface
* Develope test cases
* Generalize to work with an abstract abc_plan_type
* Parallelize code
* Expand documentation
* Try to move GaussianMixtureModelCommonCovar to Distributions package
* Look into moving cov_weighted, ess (effective sample size) and calc_dist_ks to more general pacakges
* Implement additional ABC algorithms
