# Dyn3d.jl

*A 2d/3d rigid body dynamics solver*

This package is written to support different versions of *Julia* and *Fortran*.
The main goal of this repository is to construct a rigid body-joint system
and solve forward/backward dynamics problem on it. This package is functioned
through:

- constructing 2d polygon shape rigid bodies and allow motion in 2d/3d space
- connecting bodies by joints which has 6 degree of freedoms for each
- solving motions on unconstrained(passive) degrees of freedom of joints
- solving forces on constrained degrees of freedom, allowing active motion
- plotting/making gif

To solve a rigid body dynamics problem, this package express the dynamics using
6D spatial vector developed by Roy Featherstone[^1]. The governing equations are
formulated to fit in half explicit Runge-Kutta method on index-2 differential
equations[^2]. Constrained forces on joints are represented in Lagrange multiplier
terms and solved together with motions of all degrees of freedom.

Based on the calculation of dynamical systems, `Dyn3d.jl` is also used to simulate
fluid-structure interaction(FSI) problems together with package `Whirl.jl` for
strongly coupled method. Notebook example is provided in notebook folder. Fully
coupled method taking advantage of both `Dyn3d.jl` and `Whirl.jl` is implemented
in package `FSI.jl`.

![](https://github.com/ruizhi92/Dyn3d.jl/raw/master/example_gif.gif)

## Installation

This package supports *Julia* 0.6 and 1.1 versions for now.
For *Julia 0.7* or higher versions, this package uses the local environment specified
in *Project.toml*. User doesn't need to do any set up except for possible denpendency
package required. For *Julia 0.6* version, this package's local dir need to be set by user.
Find Julia repo address by
```
julia> Pkg.dir("Dyn3d")
```
Then you can make a symlinking by
```
shell$ sudo ln -s actual_address Julia_repo_address
```

The plots in this documentation are generated using [Plots.jl](http://docs.juliaplots.org/latest/).
You might want to install that too to follow the examples.

If you have trouble in setting up the symbolic like to directory of `Dyn3d.jl`,
a simple alternative solution is:
```
include(path*"Dyn3d.jl")
```

## References

[^1]: Featherstone, Roy. Rigid body dynamics algorithms. Springer, 2014.
[^2]: Brasey, Valérie, and Ernst Hairer. "Half-explicit Runge–Kutta methods for differential-algebraic systems of index 2." SIAM Journal on Numerical Analysis 30, no. 2 (1993): 538-552.
