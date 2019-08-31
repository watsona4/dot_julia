# BayesianIntegral

This does Bayesian integration of functions of the form:

$\int_{x \in \Re^d} f(x) g(x)$

Where $$d$$ is the dimensionality of the space (so $$x$$ is $$d$$ dimensional), $$f(x)$$ is the function of interest and $$g(x)$$ is a pdf representing the density of each $x$ value.

This package uses the term Bayesian Integration to mean approximating a function with a kriging metamodel (aka a gaussian process model) and then integrating under it. A kriging metamodel has the nice feature that uncertainty about the nature of the function is explicitly modelled (unlike for instance a approximation with Chebyshev polynomials) and the Bayesian Integral uses this feature to give a Gaussian distribution representing the probabilities of various integral values. The output of the bayesian\_integral\_gaussian\_exponential function is the expectation and variance of this distribution.
