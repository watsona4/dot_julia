# Wynn.jl
[![Travis](https://travis-ci.com/J-Revell/Wynn.jl.svg?branch=master)](https://travis-ci.com/J-Revell/Wynn.jl)
[![Appveyor](https://ci.appveyor.com/api/projects/status/github/J-Revell/Wynn.jl?svg=true)](https://ci.appveyor.com/project/J-Revell/wynn-jl)

A package to facilitate the calculation of epsilon ($\epsilon$) table structures, derived from Wynn's recursive epsilon algorithm.

Suppose we are presented with a series, $S$, with partial sums $S_i$,

$\displaystyle S_i = \sum_{n=0}^i a_n$.


Wynn's epsilon algorithm computes the following recursive scheme:
$\displaystyle \epsilon_{j+1}^{(i)} = \epsilon_{j-1}^{(i+1)} + \frac{1}{\epsilon_j^{(i+1)} - \epsilon_j^{(i)}}$,

where

$\epsilon_{0}^{(i)} = S_i$, for $i=0,1,2,\ldots$

$\epsilon_{-1}^{(i)} = 0$, for $i=0,1,2,\ldots$

$\epsilon_{2j}^{(-j-1)} = 0$, for $j=0,1,2,\ldots$


The resulting table of $\epsilon_j^{(i)}$ values is known as the epsilon table.

\begin{array}{ccccc}
 & & \cdot^{\cdot^{\cdot}} & & \cdot^{\cdot^{\cdot}}\\
  & S_0 &  & \epsilon_{2}^{(-1)} & \\
 0 &  & \epsilon_{1}^{(0)} &  & \ddots \\
 & S_1 &  & \epsilon_{2}^{(0)} &  \\
 0 & &  \epsilon_{1}^{(1)} &  & \ddots \\
  & S_2 &   & \epsilon_{2}^{(1)} &  \\
 0 & &  \epsilon_{1}^{(2)} &  & \ddots \\
 & S_3 &  & \epsilon_{2}^{(2)}  &  \\
 \vdots &  & \vdots &  &  \ddots\\
\end{array}

Epsilon table values with an even $j$-th index, i.e. $\epsilon_{2j}^{(i)}$, are commonly used to compute rational sequence transformations and extrapolations, such as Shank's Transforms, and Pade Approximants.


# Example usage: computing the epsilon table for exp(x)
The first 5 terms of the Taylor series expansion for $\exp(x)$ are $S = 1 + x + x^2/2 + x^3/6 + x^4/24$. The epsilon table can be generated in the manner below:

```julia
using SymPy
using Wynn
# or, if not registered with package repository
# using .Wynn

@syms x
# first 5 terms of the Taylor series expansion of exp(x)
s = [1, x, x^2/2, x^3/6, x^4/24]

etable = EpsilonTable(s).etable
```
Retrieving the epsilon table value corresponding to $\epsilon_{j}^{(i)}$ is done by

```julia
etable[i, j]
```

## Further usage: computing the R[2/2] Pade Approximant of exp(x)
Suppose we wanted to approximate $\exp(x)$ (around $x=0$) using a rational Pade Approximant $R[l/m]$. The pade approximant $R[l/m]$ is known to correspond to the epsilon table value $\epsilon_{2m}^{(l-m)}$. Computing the R[2/2] Pade approximant is thus equivalent to $R=\epsilon_{4}^{(0)}$,
```julia
R = etable[0,4]
```
which yields

$\displaystyle R[2/2](x) = \frac{x^2 + 6x + 12}{x^2 -6x + 12}$

Comparing accuracy, for $x = 1$:

$exp(1) = 2.718281828459045$ (Native Julia function)

$S(1) = 2.7083333333333335$ (First 5 terms of Taylor series)

$R(1) = 2.7142857142857144$ (Pade R[2/2] approximation)

It can be seen that as x moves away from 0, the Pade approximant is more accurate than the corresponding Taylor series.
