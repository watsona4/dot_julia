# RiemannHilbert.jl
A Julia package for solving Riemann–Hilbert problems

[![Build Status](https://travis-ci.org/JuliaHolomorphic/RiemannHilbert.jl.svg?branch=master)](https://travis-ci.org/JuliaHolomorphic/RiemannHilbert.jl) 
[![codecov](https://codecov.io/gh/JuliaHolomorphic/RiemannHilbert.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/JuliaHolomorphic/RiemannHilbert.jl)
[![Join the chat at https://gitter.im/JuliaApproximation/ApproxFun.jl](https://badges.gitter.im/JuliaApproximation/ApproxFun.jl.svg)](https://gitter.im/JuliaApproximation/ApproxFun.jl?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)


<center>
<img src="images/sixrays.jpg" height="250" alt=".">  
</center>


A Riemann–Hilbert problem is a certain type of boundary value problem in the complex plane where an analytic function has prescribed jumps. 
They arise in integrable systems, random matrices, spectral analysis, orthogonal polynomials, and elsewhere. This package implements
the numerical method of [Olver 2011, Olver 2012] (see also review in [Trogodon & Olver 2015]) for solving Riemann–Hilbert problems, and is very much related to [RHPackage](https://github.com/dlfivefifty/RHPackage). 

For an example, the following calculates the Hastings–McLeod solution to Painlev\'e II at the origin,
which is posed on 4 rays:
```julia
# Define the contour
Γ = Segment(0, 2.5exp(im*π/6)) ∪ Segment(0, 2.5exp(5im*π/6)) ∪
		Segment(0, 2.5exp(-5im*π/6)) ∪ Segment(0, 2.5exp(-im*π/6))

# Defe the jump function
G = Fun( z -> if angle(z) ≈ π/6
					[1 0; im*exp(8im/3*z^3) 1]
				elseif angle(z) ≈ 5π/6
					[1 0; -im*exp(8im/3*z^3) 1]
				elseif angle(z) ≈ -π/6
					[1 im*exp(-8im/3*z^3); 0 1]
				elseif angle(z) ≈ -5π/6
					[1 -im*exp(-8im/3*z^3); 0 1]
				end, Γ)

# Solve the Riemann–Hilbert problem. We transpose to recast a left
# Riemann–Hilbert problem as a left one.				
Φ = transpose(rhsolve(transpose(G), 4*200)) # use 200 collocation points per ray
z = Fun(ℂ) # The function z in the complex plane
2(z*Φ[1,2])(Inf) # Evaluate 2lim_{z -> ∞} zΦ(z)_{1,2}
```

# References

1. T. Trogdon & S. Olver (2015), [Riemann–Hilbert Problems, Their Numerical Solution and the Computation of Nonlinear Special Functions](http://bookstore.siam.org/ot146/), SIAM.
2. S. Olver (2012), [A general framework for solving Riemann–Hilbert problems numerically](https://link.springer.com/article/10.1007/s00211-012-0459-7), Numer. Math., 122: 305–340.
3. S. Olver (2011), [Numerical solution of Riemann–Hilbert problems: Painlevé II](https://link.springer.com/article/10.1007/s10208-010-9079-8), Found. Comput. Maths, 11: 153–179.