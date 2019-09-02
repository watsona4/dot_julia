# SchumakerSpline.jl

*A simple shape preserving spline implementation in Julia.*

A Julia package to create a shape preserving spline. This is a shape preserving spline which is guaranteed to be monotonic and concave/convex if the data is monotonic and concave/convex. It does not use any numerical optimisation and is therefore quick and smoothly converges to a fixed point in economic dynamics problems including value function iteration. Analytical derivatives and integrals of the spline can easily be taken through the evaluate and evaluate\_integral functions.

This package has the same basic functionality as the R package called [schumaker](https://cran.r-project.org/web/packages/schumaker/index.html).

If you want to do algebraic operations on splines you can also use a schumaker spline through the [UnivariateFunctions](https://github.com/s-baumann/UnivariateFunctions.jl) package.

## Optional parameters

### Gradients.

The gradients at each of the (x,y) points can be input to give more accuracy. If not supplied these are estimated from the points provided. It is also possible to input on the gradients on the edges of the x domain and have all of the intermediate gradients imputed.

### Out of sample prediction.
There are three options for out of sample prediction.

  * Curve - This is where the quadratic curve that is present in the first and last interval are used to predict points before the first interval and after the last interval respectively.
  * Linear - This is where a line is extended out before the first interval and after the last interval. The slope of the line is given by the derivative at the start of the first interval and end of the last interval.
  * Constant - This is where the first and last y values are used for prediction before the first point of the interval and after the last part of the interval respectively.

---

```@contents
pages = ["index.md",
         "examples.md"]
Depth = 2
```
