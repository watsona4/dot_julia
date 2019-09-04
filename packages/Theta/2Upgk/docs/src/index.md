# Theta.jl Documentation

A Julia package for computing the Riemann theta function and its derivatives.

```@contents
```

## Overview
The *Riemann theta function* is the holomorphic function
```math
\theta(z,\tau) = \sum_{n\in \mathbb{Z}^g} \exp\left( \pi i n^t \tau n + 2\pi i n^t z \right)\,.
```
where ``z\in\mathbb{C}^g`` and ``\tau`` belongs to the *Siegel
upper-half space* ``\mathbb{H}_g``, which consists of all
complex symmetric ``g\times g`` matrices with positive definite imaginary part.

A *characteristic* is a vector of length ``2g``
whose entries are 0 or 1, which we write as ``\begin{bmatrix}\varepsilon
  \\\delta\end{bmatrix}``, where ``\varepsilon,\delta \in \{0,1\}^g``. The *Riemann theta function with characteristic*
``\begin{bmatrix}\varepsilon \\\delta\end{bmatrix}`` is 
```math
\theta\begin{bmatrix}\varepsilon \\\delta\end{bmatrix}(z,\tau)\,\,=\,\,\,\sum_{n\in\mathbb{Z}^g}\exp\left[\pi i \left(n+\frac{\varepsilon}{2}\right)^t \tau \left(n+\frac{\varepsilon}{2}\right)+2\pi i\left(n+\frac{\varepsilon}{2}\right)^t\left(z+\frac{\delta}{2}\right)\right]\,.
```

This package computes the Riemann theta function in Julia, with
derivatives and characteristics. We optimize the implementation for
working with a fixed Riemann matrix ``\tau`` and computing the theta
function for multiple choices of ``z``, as well as multiple derivatives and
characteristics. For more details, refer to our
upcoming preprint.


## Installation

Download Julia 1.1 and above. Start Julia and run
```julia
julia> import Pkg
julia> Pkg.add("Theta")
```

## Examples
We start with a matrix `M` in the Siegel upper-half space.
```julia
M = [0.794612+1.9986im 0.815524+1.95836im 0.190195+1.21249im 0.647434+1.66208im 0.820857+1.68942im; 
0.0948191+1.95836im 0.808422+2.66492im 0.857778+1.14274im 0.754323+1.72747im 0.74972+1.95821im; 
0.177874+1.21249im 0.420423+1.14274im 0.445617+1.44248im 0.732018+0.966489im 0.564779+1.57559im; 
0.440969+1.66208im 0.562332+1.72747im 0.292166+0.966489im 0.433763+1.91571im 0.805161+1.46982im; 
0.471487+1.68942im 0.0946854+1.95821im 0.837648+1.57559im 0.311332+1.46982im 0.521253+2.29221im];      
```

We construct a `RiemannMatrix` using `M`.
```
R = RiemannMatrix(M);
```

We can then compute the theta function on inputs `z` and `M` as follows.
```
z = [0.30657351+0.34017115im; 0.71945631+0.87045964im; 0.19963849+0.71709398im; 0.64390182+0.97413482im; 0.02747232+0.59071266im];
theta(z, R)
```

We can also compute first derivatives of theta functions by specifying
the direction using the optional argument `derivs`. The following
code computes the partial derivative of the theta function with
respect to the first coordinate of `z`.
```julia
theta(z, R, derivs=[[1,0,0,0,0]])
```

We specify higher order derivatives by adding more elements into the
input to `derivs`, where each element specifies the direction of the
derivative. For instance, to compute the partial derivative of the
theta function with respect to the first, second and fifth coordinates
of `z`, we run
```julia
theta(z, R, derivs=[[1,0,0,0,0], [0,1,0,0,0], [0,0,0,0,1]])
```

We can compute theta functions with characteristics using the optional
argument `char`.
```julia
theta(z, R, char=[[0,1,0,1,1],[0,1,1,0,0]])
```

We can also compute derivatives of theta functions with
characteristics.
```julia
theta(z, R, derivs=[[1,0,0,0,0]], char=[[0,1,0,1,1],[0,1,1,0,0]])
```

## Functions

### Computing theta functions
```@docs
theta
```

### Riemann matrix
```@docs
RiemannMatrix
```

```@docs
random_siegel
```

```@docs
siegel_transform
```

```@docs
symplectic_transform
```

### Theta characteristics
```@docs
theta_char
```

```@docs
even_theta_char
```

```@docs
odd_theta_char
```

```@docs
check_azygetic
```

### Schottky computations
#### Schottky problem in genus 4
```@docs
schottky_genus_4
```

```@docs
random_nonschottky_genus_4
```

#### Schottky problem in genus 5
```@docs
accola_chars
```

```@docs
accola
```

```@docs
random_nonaccola
```

```@docs
fgsm_chars
```

```@docs
fgsm
```

```@docs
random_nonfgsm
```

## Index

```@index
```
