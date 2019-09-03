###############################################################################
#
# The primary module for computing the Riemann theta function.
#
# .. math::
#
#   Θ(z, ω) = Σ
    # \theta(z, \Omega) = \sum_{n \in \mathbb{Z}^g}
                        # e^{2 \pi i \left( \tfrac{1}{2} n \cdot \Omega n
                           # + n \cdot z \right)}
#
#
#  Original Authors
#  -------
#  * Chris Swierczewski (@cswiercz) - September 2012, July 2016
#  * Grady Williams (@gradyrw) - October 2012
#  * Jeremy Upsal (@jupsal) - July 2016
#
# References
# ----------
#
# .. [CRTF] B. Deconinck, M.  Heil, A. Bobenko, M. van Hoeij and M. Schmies,
#    Computing Riemann Theta Functions, Mathematics of Computation, 73, (2004),
#    1417-1442.
#
# .. [DLMF] B. Deconinck, Digital Library of Mathematics Functions - Riemann
#    Theta Functions, http://dlmf.nist.gov/21
#
# .. [SAGE] Computing Riemann theta functions in Sage with applications.
#    C. Swierczewski and B. Deconinck.Submitted for publication.  Available
#    online at
#    http://depts.washington.edu/bdecon/papers/pdfs/Swierczewski_Deconinck1.pdf
#
###############################################################################

"""
         oscillatory_part(zs::Vector{Vector{ComplexF64}},
                          Ω::Matrix{ComplexF64};
                          eps::Float64=1e-8,
                          derivs::Vector{Vector{ComplexF64}}=Vector{ComplexF64}[],
                          accuracy_radius::Float64=5.)::Vector{ComplexF64}

Return the value of the oscillatory part of the Riemann theta function for Ω and
all z in `zs` if `derivs` is empty, or the derivatives at all z in `zs` for the
given directional derivatives in `derivs`.

Parameters
----------
- `zs` : A vector of complex vectors at which to evaluate the Riemann theta function.
- `Omega` : A Riemann matrix.
- `eps` : (Default: 1e-8) The desired numerical accuracy.
- `derivs` : A vector of complex vectors giving a directional derivative.
- `accuracy_radius` : (Default: 5.) The radius from the g-dimensional origin
where the requested accuracy of the Riemann theta is guaranteed when computing
derivatives. Not used if no derivatives of theta are requested.

Returns
-------
- The value of the oscillatory part of the Riemann theta function at each point appearing in `z`.
"""
function oscillatory_part(zs::Vector{Vector{ComplexF64}},
                          Ω::Matrix{ComplexF64};
                          eps::Float64=1e-8,
                          derivs::Vector{Vector{ComplexF64}}=Vector{ComplexF64}[],
                          accuracy_radius::Float64=5.)
    # extract the requested information: the real part, inverse of the
    # imaginary part, and the cholesky decomposition of the imaginary part
    X = real.(Ω)
    Y = imag.(Ω)

    # In python version numpy.linalg.cholesky returns the lower triangular
    #  matrix, which is then transposed. Julia's cholesky returns the upper
    #  triangular matrix, hence no need to transpose.
    T = Matrix(cholesky(Y).U)

    Yinv = inv(Y)

    # compute the integer points over which we approximate the infinite sum to
    # the requested accuracy
    R = radius(eps, T, derivs, accuracy_radius)
    S = innerpoints(T, R)

    finite_sum(X, Yinv, T, zs, S, derivs)
end


"""
         exponential_part(zs::Vector{Vector{ComplexF64}},
                          Ω::Matrix{ComplexF64})::Vector{Float64}

Return the value of the exponential part of the Riemann theta function for Ω and
all z in `zs`.

Parameters
----------
- `zs` : A vector of complex vectors at which to evaluate the Riemann theta function.
- `Omega` : A Riemann matrix.

Returns
-------
The value of the exponential part of the Riemann theta function at
each point appearing in `zs`.

"""
function exponential_part(zs::Vector{Vector{ComplexF64}},
                          Ω::Matrix{ComplexF64})::Vector{Float64}
    # extract the imaginary parts of z and the inverse of the imaginary part
    # of Omega
    y = [ imag.(z) for z in zs ]
    Yinv = inv(imag.(Ω))

    # apply the quadratic form to each vector in z
    map(y -> π * dot(y, Yinv * y), y)
end


"""
     riemanntheta(zs::Vector{Vector{ComplexF64}},
                  Ω::Matrix{ComplexF64};
                  eps::Float64=1e-8,
                  derivs::Vector{Vector{ComplexF64}}=Vector{ComplexF64}[],
                  accuracy_radius::Float64=5.)::Vector{ComplexF64}

Return the value of the Riemann theta function for Ω and all z in `zs` if
`derivs` is empty, or the derivatives at all z in `zs` for the given directional
derivatives in `derivs`.

Parameters
----------
- `zs` : A vector of complex vectors at which to evaluate the Riemann theta function.
- `Omega` : A Riemann matrix.
- `eps` : (Default: 1e-8) The desired numerical accuracy.
- `derivs` : A vector of complex vectors giving a directional derivative.
- `accuracy_radius` : (Default: 5.) The radius from the g-dimensional origin
where the requested accuracy of the Riemann theta is guaranteed when computing
derivatives. Not used if no derivatives of theta are requested.

Returns
-------
The value (or derivative) of the Riemann theta function at each point in `zs`.
"""
function riemanntheta(zs::Vector{Vector{ComplexF64}},
                      Ω::Matrix{ComplexF64};
                      eps::Float64=1e-8,
                      derivs::Vector{Vector{ComplexF64}}=Vector{ComplexF64}[],
                      accuracy_radius::Float64=5.)::Vector{ComplexF64}

    u = exponential_part(zs, Ω)
    v = oscillatory_part(zs, Ω, eps=eps, derivs=derivs,
                         accuracy_radius=accuracy_radius)

    exp.(u) .* v
end
