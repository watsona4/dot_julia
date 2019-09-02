# Supported Approximation Methods

In addition the following approximation schemes are available, each of which can be used in any number of dimensions (subject to having enough computational power)
* OLS regression - Performs an OLS regression of the data and generates a Sum\_Of\_Functions containing the resultant approximation. This should work well in many dimensions.
* Chebyshev polynomials - Creates a Sum\_Of\_Functions that uses Chebyshev polynomials to approximate a certain function. Unlike the other approximation schemes this does not take in an arbitrary collection of datapoints but rather takes in a function that it evaluates at certain points in a grid to make an approximation function. This might be useful if the original function is expensive (so you want a cheaper one). You might also want to numerically integrate a function by getting a Chebyshev approximation function that can be analytically integrated. See Judd (1998) for details on how this is done.
* Mars regression spline - Creates a Sum\_Of\_Piecewise\_Functions representing a MARS regression spline. See Friedman (1991) for an explanation of the spline.
