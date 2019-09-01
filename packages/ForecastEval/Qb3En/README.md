# ForecastEval

[![Build Status](https://travis-ci.org/colintbowers/ForecastEval.jl.svg?branch=master)](https://travis-ci.org/colintbowers/ForecastEval.jl)


A module for the Julia language that implements several statistical tests from the forecast evaluation literature.

## Main features

This module allows Julia users to evaluate competing forecasts using several tests from the forecast evaluation literature.

The following bivariate forecast evaluation procedures are implemented:
* Diebold, Mariano (1995) "Comparing Predictive Accuracy", Journal of Business and Economic Statistics 13 (3), pp. 253-263

The following multivariate forecast evaluation procedures are implemented:
* White (2000) "A Reality Check for Data Snooping", Econometrica 68 (5), pp. 1097-1126
* Hansen (2005) "A Test for Superior Predictive Ability", Journal of Business and Economic Statistics 23 (4), pp. 365-380
* Hansen, Lunde, Nason (2011) "The Model Confidence Set", Econometrica 79 (2), pp. 453-497

## Installation

This package should be added using `Pkg.add("ForecastEval")`, and can then be called with `using ForecastEval`. The package has three dependencies (currently): StatsBase, Distributions, and DependentBootstrap. Support for DataFrames or TimeArrays is not currently available. If you use these types, convert your data to vectors or matrices before calling functions from this package.

This package supports Julia v1.0. If you are running v0.5 or v0.6, you will need to use `Pkg.pin("ForecastEval", v"0.1.0")` at the REPL. Versions prior to v0.5 are not supported.

## Usage

In these notes, I will briefly cover the names of the main functions, input types, and output types. All of these functions/types have been documented extensively using Julia's docstrings capability, and so users can find out detailed information about the tests of interest using the `?x` command at the Julia REPL, where `x` denotes the function name or type name of interest.

#### Diebold-Mariano Test (DM)

Function name: `dm`

Input types: `DMHAC` and `DMBoot`

Output type: `DMTest`

Please use `?x`, where `x` is any of these names, at the REPL for more information on each type.

A keyword signature for `dm` is also provided and it is anticipated that most users will interact with the test in this way. Please type `?dm` at the REPL for more information.

Note that there are currently two options for performing a Diebold-Mariano test:

1) The mean loss differential is scaled by a HAC variance estimate, and Normality of this statistic is assumed via a central limit theorem. This is sometimes referred to as the asymptotic method, and uses the `DMHAC` type as input, or can be called using the keyword signature.

2) The mean loss differential is bootstrapped using a block bootstrap procedure. This method uses the `DMBoot` type as input, or can be called using the keyword signature.

#### Reality Check (RC)

Function name: `rc`

Input types: `RCBoot`

Output type: `RCTest`

Please use `?x`, where `x` is any of these names, at the REPL for more information on each type.

A keyword signature for `rc` is also provided and it is anticipated that most users will interact with the test in this way. Please type `?rc` at the REPL for more information.

#### Superior Predictive Ability (SPA) Test

Function name: `spa`

Input types: `SPABoot`

Output type: `SPATest`

Please use `?x`, where `x` is any of these names, at the REPL for more information on each type.

A keyword signature for `spa` is also provided and it is anticipated that most users will interact with the test in this way. Please type `?spa` at the REPL for more information.

#### Model Confidence Set (MCS)

Function name: `mcs`

Input types: `MCSBoot` and `MCSBootLowRAM`

Output type: `MCSTest`

Please use `?x`, where `x` is any of these names, at the REPL for more information on each type.

A keyword signature for `mcs` is also provided and it is anticipated that most users will interact with the test in this way. Please type `?mcs` at the REPL for more information.

The `MCSBootLowRAM` uses a different algorithm to `MCSBoot` that has roughly half the RAM requirements but takes twice as long to run. Note that the `MCSBootLowRAM` results are not guaranteed to be identical to those of `MCSBoot`. The vast majority of users will want to use `MCSBoot`, since `MCSBootLowRAM` doesn't allow many additional forecast models to be included (RAM requirements go up by a power law in the number of models, not linearly). I would be very receptive to any pull requests that are able to speed up the run-time of `MCSBootLowRAM`. The essential difference between the two algorithms is that `MCSBoot` wastes additional RAM but with the benefit of being able to perform `mean` computations on matrices in column-major order using BLAS routines.  
