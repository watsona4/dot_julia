# SeparatingAxisTheorem2D.jl

[![Build Status](https://travis-ci.org/schmrlng/SeparatingAxisTheorem2D.jl.svg?branch=master)](https://travis-ci.org/schmrlng/SeparatingAxisTheorem2D.jl)
[![Build status](https://ci.appveyor.com/api/projects/status/6kp65v99njhhys29?svg=true)](https://ci.appveyor.com/project/schmrlng/separatingaxistheorem2d-jl)
[![codecov.io](http://codecov.io/github/schmrlng/SeparatingAxisTheorem2D.jl/coverage.svg?branch=master)](http://codecov.io/github/schmrlng/SeparatingAxisTheorem2D.jl?branch=master)

This package implements collision detection for 2D shapes based on the [separating axis theorem](https://en.wikipedia.org/wiki/Hyperplane_separation_theorem#Use_in_collision_detection). Shape representations leverage [StaticArrays.jl](https://github.com/JuliaArrays/StaticArrays.jl) for computational efficiency; this package targets applications potentially requiring millions of collision checks, e.g., [robot motion planning](https://github.com/schmrlng/MotionPlanning.jl).

## Shapes
This package exports the abstract type `Shape2D` and the following concrete types for collision checking:
- `Point` (alias for `AbstractVector{<:Number}`)
- `AxisAlignedBoundingBox <: Shape2D` (equivalently, `AABB`)
    - `AABB((xl, xu), (yl, yu))`: constructs an instance corresponding to the set [`xl`, `xu`] × [`yl`, `yu`].
    - `AABB(Δx, Δy)`: constructs an instance corresponding to the set [-`Δx/2`, `Δx/2`] × [-`Δy/2`, `Δy/2`].
- `LineSegment <: Shape2D`
    - `LineSegment(v, w)` constructs a line segment connecting `v` and `w`.
- `Polygon <: Shape2D`
    - `Polygon(points...)`: constructs a convex polygon with vertices `points`. `points` must be supplied in counter-clockwise order.
    - `Triangle(p1, p2, p3)`: convenience constructor that reorders three points into CCW order before calling `Polygon`.
- `Circle <: Shape2D`
    - `Circle(c, r)`: constructs a circle centered at `c` with radius `r`.
    - `Circle(r)`: constructs a circle centered at the origin with radius `r`.
- `CompoundShape <: Shape2D`
    - `CompoundShape(parts...)`: groups a list of other `Shape2D`s into a single (possible non-convex) collision object.

This package also exports a few methods for transforming/creating new shapes from others.
- `Transformation`s from [CoordinateTranformations.jl](https://github.com/FugroRoames/CoordinateTransformations.jl) may be applied to shapes to produce the expected output; some care must be taken, however, to ensure that only rigid transformations are applied to `Circle`s as there is currently no `Ellipse` shape implemented.
- `inflate(X, ε; round_corners=true)`: inflates a shape `X` by a buffer `ε` > 0. The `round_corners` keyword argument may be set to `false` to ensure that inflating an `AABB`, `LineSegment`, or `Polygon` yields just a single `Polygon` (performing an approximate inflation) instead of a `CompoundShape` consisting of a `Polygon` and `Circle`s.
- `sweep`: this function is used internally to facilitate continuous (i.e., "swept") collision detection.
    - `sweep(X1, X2)`: yields a shape corresponding to the area swept out by moving shape `X1` to shape `X2` (if sweeping `X1` to `X2` involves a rotation, this rotation should be "reasonably small" or this will probably produce junk).
    - `sweep(X, f1, f2)`: equivalent to `sweep(f1(X), f2(X))`.

## Collision Checking
SeparatingAxisTheorem2D.jl defines the following functions for collision checking:
- `intersecting` for discrete collision detection.
    - `intersecting(X, Y)`: true iff `X` and `Y` are in collision.
    - `intersecting(X, Y, f)`: true iff `X` and `f(Y)` are in collision.
- `sweep_intersecting` for continuous collision detection.
    - `X` static and `Y` dynamic
        - `sweep_intersecting(X, Y1, Y2)`: true iff `X` and `sweep(Y1, Y2)` are in collision.
        - `sweep_intersecting(X, Y, f1, f2)`: true iff `X1` and `sweep(f1(X), f2(X))` are in collision.
    - `X` and `Y` both dynamic
        - `sweep_intersecting(X, fX1, fX2, Y, fY1, fY2)`: supposing that `X` is getting swept from transformation `fX1` to `fX2` and `Y` is simultaneously getting swept from transformation `fY1` to `fY2`, returns true iff the shapes are ever in collision.
