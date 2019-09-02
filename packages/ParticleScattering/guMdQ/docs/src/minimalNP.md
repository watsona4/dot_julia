# [Choosing Minimal N and P](@id minimalNP)

## Discretization Parameter N

For each non-circular shape in a given scattering problem, we must choose the
number of discretization nodes `2N` that not only fulfills some accuracy
requirement, but also is not large enough to slows down the solution process.
Although each shape is only solved or once in the pre-processing stage, with
``O(N^3)`` time complexity this stage can be slower than the system matrix
solution for large values of `N`.

As the relationship between `N` and the resulting error depends not only on the
geometry and diameter of the shape, but also on the wavelengths inside and
outside of it, a general approach to computing `N` is crucial for dependable
results.
Moreover, there are many ways to quantify the error for a given discretization.
Here we utilize a fictitious-source approach: the potential densities
``\sigma``, ``\mu`` are solved for assuming (for example) a plane wave outside
the particle and a line source inside it.
The fields induced by these densities outside the particle should then be equal
to that of the line source, up to some error.
Specifically, this error is measured on a circle of radius

```julia
R_multipole*maximum(hypot.(s.ft[:,1],s.ft[:,2]))
```

as this is the scattering disc on which the translation to cylindrical harmonics
(Bessel & Hankel functions) are performed (and beyond which any gain or loss of
accuracy due to `N` is mostly irrelevant).

Above a certain `N`, this error tends to decay as ``O(N^{-3})``, but with a
multiplicative factor that is heavily dependent on the particle and wavelength.
With [`minimumN`](@ref), we first guess a value and then use a binary search to find the
minimal `N` satisfying some error tolerance `tol`.

## Multipole Parameter P
