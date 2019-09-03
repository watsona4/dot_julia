# SimpleCarModels.jl

[![Build Status](https://travis-ci.org/schmrlng/SimpleCarModels.jl.svg?branch=master)](https://travis-ci.org/schmrlng/SimpleCarModels.jl)
[![Build status](https://ci.appveyor.com/api/projects/status/0eoauf078if1uywp?svg=true)](https://ci.appveyor.com/project/schmrlng/simplecarmodels-jl)
[![codecov.io](http://codecov.io/github/schmrlng/SimpleCarModels.jl/coverage.svg?branch=master)](http://codecov.io/github/schmrlng/SimpleCarModels.jl?branch=master)

This package extends the interfaces defined in [`DifferentialDynamicsModels.jl`](https://github.com/schmrlng/DifferentialDynamicsModels.jl) to simple car dynamics of the form
<p align="center"><img src="https://latex.codecogs.com/gif.latex?%5Cinline%20%7B%5Cbegin%7Bbmatrix%7D%20%5Cdot%20x%20%5C%5C%20%5Cdot%20y%20%5C%5C%20%5Cdot%5Ctheta%5Cend%7Bbmatrix%7D%7D%20%3D%20%5Cbegin%7Bbmatrix%7D%20v%20%5Ccos%28%5Ctheta%29%20%5C%5C%20v%20%5Csin%28%5Ctheta%29%20%5C%5C%20v%20%5Ckappa%5Cend%7Bbmatrix%7D." alt="simple car dynamics"/></p>

The state consists of position ![(x,y)](https://latex.codecogs.com/gif.latex?%5Cinline%20%28x%2C%20y%29) and heading ![θ](https://latex.codecogs.com/gif.latex?%5Cinline%20%5Ctheta) in the plane. The control inputs are speed ![v](https://latex.codecogs.com/gif.latex?%5Cinline%20v) and curvature ![κ](https://latex.codecogs.com/gif.latex?%5Cinline%20%5Ckappa), or some derivative of each of them (e.g., curvature rate ![κ̇](https://latex.codecogs.com/gif.latex?%5Cinline%20%5Cdot%5Ckappa) as input ensures trajectories with continuous curvature) with the state and dynamics equation correspondingly augmented. This package exports the type `SimpleCarDynamics{Dv,Dκ} <: DifferentialDynamics` to represent these dynamics, where `Dv` and `Dκ` denote the number of integrators in the speed and curvature control inputs respectively.

In addition to providing these dynamics and a few methods for exact propagation, this package also contains pure Julia implementations of minimum arc length [Dubins](http://planning.cs.uiuc.edu/node821.html) and [Reeds-Shepp](http://planning.cs.uiuc.edu/node822.html) steering for a simple car with minimum turning radius `r`. These implementations aim to be non-allocating and highly performant (e.g., for use in robotic motion planning where computing millions of steering connections in a few seconds may be necessary), and may be accessed through the `SteeringBVP` interface defined in [`DifferentialDynamicsModels.jl`](https://github.com/schmrlng/DifferentialDynamicsModels.jl):
- `DubinsSteering(; v=1, r=1)` returns a `DubinsSteering` instance which may be called with two [`SE2State`](https://github.com/schmrlng/SimpleCarModels.jl/blob/master/src/models.jl#L14)s as input, or any pair of [`StaticVector`](https://github.com/JuliaArrays/StaticArrays.jl)s of length 3.
- `ReedsSheppSteering(; v=1, r=1)` returns a `ReedsSheppSteering` instance which may be called as above.

or through specialized functions:
- `dubins_length(q0, qf; r=1)` and `dubins_waypoints(q0, qf, dt_or_N; v=1, r=1)` give the length and a `Vector` of states along the optimal Dubins steering curve respectively. `dt_or_N` may be an `AbstractFloat` or an `Int`, corresponding to a desired time spacing `dt` (with car speed `v`) or a desired total number of equally spaced waypoints `N`.
- `reedsshepp_length(q0, qf; r=1)` and `reedsshepp_waypoints(q0, qf, dt_or_N; v=1, r=1)` give the length and a `Vector` of states along the optimal Reeds-Shepp steering curve respectively.
