################################################################################
# Matrix containing the number of observations and the condition
# number per pixel

@doc raw"""
    mutable struct NobsMatrixElement

This structure encodes the condition matrix for a pixel in the map. It
is essentially matrix M_p in Eq. (10) of KurkiSuonio2009, but with
steroids, as it implements the following fields:

- `m`: the 3×3 matrix in Eq. (10)
- `invm`: the 3×3 inverse of `m`
- `invcond`: the inverse of the condition number *rcond* for `m`; this
  field is useful to check whether the samples in a TOD and the attack
  angles are sufficient to constrain a unique solution for I, Q, and U
  for that pixel.
- `neglected`: a Boolean flag telling whether the pixel was skipped or
  not during map-making (this usually happens if `invcond` is too
  small)

A typical use case is an array of `NobsMatrixElement` objects in an
array that get updated via [`update_nobs_matrix!`](@ref), like in the
following example:

```julia
NPIX = 10   # Number of pixels in the map
nobs_matrix = [NobsMatrixElement() for i in 1:NPIX]

# The variables psi_angle, sigma_squared, pixidx, and flagged
# must have been defined somewhere else; they contain the TOD
update_nobs_matrix!(nobs_matrix, psi_angle, sigma_squared, pixidx, flagged)
```

"""
mutable struct NobsMatrixElement{T <: Real}
    # We do not define "m" as symmetric, as we want to update its
    # fields one by one; however, we only consider the upper part
    m::Array{T, 2}
    invm::Symmetric{T, Array{T, 2}}
    invcond::T

    # If "true", do not consider this pixel in the solution, as it was
    # not covered enough by the scanning strategy
    neglected::Bool

    NobsMatrixElement{T}() where {T <: Real} = new(
        Symmetric(zeros(T, 3, 3)),
        Symmetric(zeros(T, 3, 3)),
        0.0,
        true,
    )
end

function Base.show(io::IO, nobsmatr::NobsMatrixElement{T}) where {T <: Real}
    print(io, "NobsMatrixElement(invcond => $(nobsmatr.invcond), neglected => $(nobsmatr.neglected))")
end

function Base.show(io::IO, ::MIME"text/plain", nobsmatr::NobsMatrixElement{T}) where {T <: Real}
    println(
        io,
        @sprintf(
            """NobsMatrixElement:
Inverse condition number.......... %e
Neglected......................... %s
Matrix:
    %.5f   %.5f   %.5f
    %.5f   %.5f   %.5f
    %.5f   %.5f   %.5f
Inverse matrix:
    %.5f   %.5f   %.5f
    %.5f   %.5f   %.5f
    %.5f   %.5f   %.5f
    """,
            nobsmatr.invcond,
            nobsmatr.neglected,
            nobsmatr.m[1, 1], nobsmatr.m[1, 2], nobsmatr.m[1, 3],
            nobsmatr.m[2, 1], nobsmatr.m[2, 2], nobsmatr.m[2, 3],
            nobsmatr.m[3, 1], nobsmatr.m[3, 2], nobsmatr.m[3, 3],
            nobsmatr.invm[1, 1], nobsmatr.invm[1, 2], nobsmatr.invm[1, 3],
            nobsmatr.invm[2, 1], nobsmatr.invm[2, 2], nobsmatr.invm[2, 3],
            nobsmatr.invm[3, 1], nobsmatr.invm[3, 2], nobsmatr.invm[3, 3],
        )
    )
end

@doc raw"""
    update_nobs!(nobs::NobsMatrixElement{T}; threshold = 1e-7)

This function makes sure that all the elements in `nobs` are
synchronized. It should be called whenever the field `nobs.m` (matrix
M_p in Eq. 10 of KurkiSuonio2009) has changed.

"""
function update_nobs!(nobs::NobsMatrixElement{T}; threshold = 1e-7) where {T <: Real}
    c = cond(nobs.m)

    if isfinite(c)
        nobs.invm = inv(Symmetric(nobs.m))
        nobs.invcond = 1 / c
        nobs.neglected = nobs.invcond < threshold
    else
        nobs.invcond = 0.0
        nobs.neglected = true
    end
end

@doc raw"""
    update_nobs_matrix!(nobs_matrix::Vector{NobsMatrixElement{T}}, psi_angle, sigma_squared, pixidx, flagged)

Apply Eq. (10) of KurkiSuonio2009 iteratively on the samples of a TOD
to update matrices ``M_p`` in `nobs_matrix`. The meaning of the
parameters is the following:

- `nobs_matrix` is the structure that gets updated by this function
- `psi_angle` is an array of `N` elements, containing the polarization
  angles (in radians)
- `sigma_squared` is an array of `N` elements, each containing the
  value of σ^2 for the samples in the TOD
- `pixidx` is an array of `N` elements, containing the pixel index
  observed by the TOD
- `flagged` is a Boolean array of `N` elements; `true` means that the
  sample in the TOD should not be used to produce the map. This can be
  used to produce jackknives and to neglect moving objects in the TOD

"""
function update_nobs_matrix!(
    nobs_matrix::Vector{NobsMatrixElement{T}},
    psi_angle,
    sigma_squared,
    pixidx,
    flagged,
) where {T <: Real}

    @assert length(psi_angle) == length(sigma_squared)
    @assert length(psi_angle) == length(pixidx)
    @assert length(psi_angle) == length(flagged)

    for (idx, curpix, curpsi, curflagged) in zip(
        1:length(pixidx),
        pixidx,
        psi_angle,
        flagged,
    )
        curflagged && continue

        constant = 1 / sigma_squared[idx]

        sin_term, cos_term = sincos(2 * curpsi)
        nobs_matrix[curpix].m[1, 1] += constant
        nobs_matrix[curpix].m[1, 2] += cos_term * constant
        nobs_matrix[curpix].m[1, 3] += sin_term * constant

        nobs_matrix[curpix].m[2, 2] += cos_term^2 * constant
        nobs_matrix[curpix].m[2, 3] += cos_term * sin_term * constant

        nobs_matrix[curpix].m[3, 3] += sin_term^2 * constant
    end
end
