# Hyperbolic Plane


[![Build Status](https://travis-ci.org/scheinerman/HyperbolicPlane.jl.svg?branch=master)](https://travis-ci.org/scheinerman/HyperbolicPlane.jl)


[![codecov.io](http://codecov.io/github/scheinerman/HyperbolicPlane.jl/coverage.svg?branch=master)](http://codecov.io/github/scheinerman/HyperbolicPlane.jl?branch=master)



The `HyperbolicPlane` module provides basic objects
(such as points, segments, rays, lines, polygons, and circles) in the Hyperbolic
plane and visualization in the Poincaré Disc.

Documentation is in the
[Wiki](https://github.com/scheinerman/HyperbolicPlane.jl/wiki). Also see the
[examples](https://github.com/scheinerman/HyperbolicPlane.jl/tree/master/examples).


The drawing functions rely on [`SimpleDrawing`](https://github.com/scheinerman/SimpleDrawing.jl)
(a modest extension of [`Plots`](https://github.com/JuliaPlots/Plots.jl)).

We also require these modules:
+ [`LinearFractionalTransformations`](https://github.com/scheinerman/LinearFractionalTransformations.jl):
provides Möbius transformations.
+ [`AbstractLattices`](https://github.com/scheinerman/AbstractLattices.jl):
Defines `∨` and `∧`.
