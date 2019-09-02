# PlanarConvexHulls

[![Build Status](https://travis-ci.com/tkoolen/PlanarConvexHulls.jl.svg?branch=master)](https://travis-ci.com/tkoolen/PlanarConvexHulls.jl)
[![Codecov](https://codecov.io/gh/tkoolen/PlanarConvexHulls.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/tkoolen/PlanarConvexHulls.jl)
[![](https://img.shields.io/badge/docs-latest-blue.svg)](https://tkoolen.github.io/PlanarConvexHulls.jl/dev)
[![](https://img.shields.io/badge/docs-stable-blue.svg)](https://tkoolen.github.io/PlanarConvexHulls.jl/stable)

PlanarConvexHulls provides a `ConvexHull` type, which represents the convex hull of a set
of 2D points by its extreme points. Functionality includes:

* convexity test
* construction of a convex hull given a set of points
* area
* centroid
* point-in-convex-hull test
* closest point within convex hull
* equivalent halfspace representation of the convex hull
