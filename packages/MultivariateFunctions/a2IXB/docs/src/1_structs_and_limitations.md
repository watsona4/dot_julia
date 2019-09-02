# Structs

There are four main MultivariateFunction structs that are part of this package. These are:
* PE\_Function - This is the basic function type. It has a form of $$ae^{b(x-base)} (x-base)^d$$.
* Sum\_Of\_Functions - This is an array of PE\_Functions. Note that by adding PE\_Functions we can replicate any given polynomial. Hence from Weierstrass' approximation theorem we can approximate any continuous function on a bounded domain to any desired level of accuracy (whether this is practical in numerical computing depends on the function being approximated).
* Piecewise\_Function - This defines a different MultivariateFunction for each part of the x domain.
* Sum\_Of\_Piecewise\_Functions - Mathematically this does the same job as a Piecewise\_Function but is dramatically more efficient when the contribution of different dimensions to the Piecewise\_Function is additively separable.

It is possible to perform any additions, subtractions, multiplications between any two MultivariateFunctions and between Ints/Floats and any MultivariateFunction. No division is allowed and it is not possible to raise a MultivariateFunction to a negative power. This is to ensure that all Multivariatefunctions are analytically integrable and differentiable. This may change in future releases.

## Major limitations
* It is not possible to divide by Multivariate functions or raise them by a negative power.
* When multiplying PE\_Functions with different base dates there is often an issue of very high or very low numbers that go outside machine precision. If one were trying to change a PE\_Function from base 2010 to 50, this would not generally be possible. This is because to change $$ae^{x-2020}$$ to $$qe^{x- 50}$$ we need to premultiply the first expression by $$e^{-1950}$$ which is often a tiny number. In these cases it is better to do the algebra on paper and rewriting the code accordingly as often base changes cancel out on paper. It is also good to change bases as rarely as possible. If different Multivariate functions use different bases then there is a need to base change when multiplying them which can result in errors. Note that if base changes are segment in the x domain by means of a piecewise function then they should never interact meaning it is ok to use different bases here.

## Date Handling

* All base dates are immediately converted to floats and are not otherwise saved. Thus there is no difference between a PE\_Function created with a base as a float and one created with the matching date. This is done to simplify the code. All date conversions is done by finding the year fractions between the date and the global base date of Date(2000,1,1). This particular global base date should not affect anything as long as it is consistent. It is relatively trivial to change it (in the date\_conversions.jl file) and recompile however if desired.
