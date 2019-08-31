To assign boxes to points, we need a reference point. Throughout this package, the minima along each coordinate
axis of the space is used as the reference point.

The following function takes a set of `points` and a binning scheme `ϵ`, and returns what the minima along each coordinate axis is, along with the step sizes along each axis resulting from the binning scheme provided by `ϵ`.

```@docs
minima_and_stepsizes(points, ϵ)
```
