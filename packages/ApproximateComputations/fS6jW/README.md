# ApproximateComputations.jl

[![Build Status](https://travis-ci.org/NTimmons/ApproximateComputations.jl.svg?branch=master)](https://travis-ci.org/NTimmons/ApproximateComputations.jl)[![codecov](https://codecov.io/gh/NTimmons/ApproximateComputations.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/NTimmons/ApproximateComputations.jl)

[Interactive Documentation Here](https://github.com/NTimmons/ApproximateComputations.jl/blob/master/docs/ApproximateComputations_Readme.ipynb)

ApproximateComputations.jl is a library for the automatic applicaiton approximate computation software techniques to existing code. In this context, software approximation is where we perform some transformation to existing code to reduce the accuracy for gain in performance.

This is usually applied through function replacement. The standard workflow is to determine the maximum or average acceptable error for a given code block and then reducing the accuracy of the function so that as little work as possible is spent on gaining a more acurate result that the acceptable level.

