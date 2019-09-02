import Healpix
export std2fwhm, fwhm2std, gaussian_beam

@doc raw"""
    std2fwhm(stddev)

Convert a standard deviation into a Full Width Half Maximum (FWHM) value. The
measure unit for `stddev` can be arbitrary, as the transformation is linear.
See also `fwhm2std`.
"""
std2fwhm(stddev) = 2 * sqrt(2 * log(2)) * stddev

@doc raw"""
    std2fwhm(stddev)

Convert a standard deviation into a Full Width Half Maximum (FWHM) value. The
measure unit for `stddev` can be arbitrary, as the transformation is linear.
See also `std2fwhm`.
"""
fwhm2std(fwhm) = fwhm / (2 * sqrt(2 * log(2)))

@doc raw"""
    gaussian_beam!(beam_map::Healpix.Map{T,O}, angle_std_rad; normalization = 1.0) where {T,O <: Healpix.Order}

Save a map of a circual Gaussian beam in `beam_map`. The width of the beam is
provided through the parameter `angle_std_rad`, which is expressed in radians.
If you want to specify the FWHM instead, use `fwhm2std` like in the following
example:

````julia
import Healpix
nside = 1024
beam_map = Healpix.Map{Float64, RingOrder}(nside)

# Assume 2.5° of FWHM
gaussian_beam!(beam_map, 2.5 |> fwhm2std)
````

See also `gaussian_beam`.
"""
function gaussian_beam!(beam_map::Healpix.Map{T,O}, angle_std_rad; normalization = 1.0) where {T,O <: Healpix.Order}
    for pixidx in 1:beam_map.resolution.numOfPixels
        theta, _ = Healpix.pix2ang(beam_map, pixidx)
        beam_map[pixidx] = normalization * exp(-theta^2 / (2 * angle_std_rad))
    end
end

function gaussian_beam(nside::Integer, angle_std_rad; normalization = 1.0)
    beam_map = Healpix.Map{Float64,Healpix.RingOrder}(nside)
    gaussian_beam!(beam_map, angle_std_rad, normalization = normalization)

    beam_map
end

function gaussian_beam(res::Healpix.Resolution, angle_std_rad; normalization = 1.0)
    gaussian_beam(res.nside, angle_std_rad, normalization = normalization)
end

@doc raw"""
    gaussian_beam(res::Healpix.Resolution, angle_std_rad; normalization = 1.0) where {T,O <: Healpix.Order}
    gaussian_beam(nside::Integer, angle_std_rad; normalization = 1.0) where {T,O <: Healpix.Order}

Save a map of a circual Gaussian beam in `beam_map`. The width of the beam is
provided through the parameter `angle_std_rad`, which is expressed in radians.
If you want to specify the FWHM instead, use `fwhm2std` like in the following
example:

````julia
# Assume 2.5° of FWHM
beam_map = gaussian_beam(1024, 2.5 |> fwhm2std)
````

See also `gaussian_beam!`.
"""
gaussian_beam

struct BeamMoments
    S::Array{Float32,1}
    M::Array{Float32,2}
end

@doc raw"""

    beam_m(beam_map, l, m, n)

Calculate the moment `(l, m, n)` of the beam in the Healpix map `beam_map`. Beam
moments are defined in Appendix A of the paper "Planck 2013 results. LFI
calibration" (Planck collaboration, A&A, 2013),
https://dx.doi.org/10.1051/0004-6361/201321527.

This function does not take into account the factor `N` (normalization of the beam).
You can compute it using `beam_m(beam_map, 0, 0, 0)`.

"""
function beam_m(beam_map, l::Integer, m::Integer, n::Integer)
    result = 0.0
    for idx in 1:length(beam_map)
        θ, ϕ = Healpix.pix2ang(beam_map, idx)

        # We could have used `Healpix.ang2vec`, but we need the value
        # of sinθ in order to calculate dΩ = sinθ⋅dθ⋅dϕ
        sinθ, cosθ = sincos(θ)
        sinϕ, cosϕ = sincos(ϕ)
        
        x = sinθ * cosϕ
        y = sinθ * sinϕ
        z = cosθ
        
        result += x^l * y^m * z^n * sinθ * beam_map[idx]
    end
    result
end

function beam_moments(beam_map)
    N = beam_m(beam_map, 0, 0, 0)

    S = [
        beam_m(beam_map, 1, 0, 0) / N,
        beam_m(beam_map, 0, 1, 0) / N,
        beam_m(beam_map, 0, 0, 1) / N,
    ]

    M = [
        [(beam_m(beam_map, 2, 0, 0) / N)  (beam_m(beam_map, 1, 1, 0) / N)  (beam_m(beam_map, 1, 0, 1) / N)];
        [(beam_m(beam_map, 1, 1, 0) / N)  (beam_m(beam_map, 0, 2, 0) / N)  (beam_m(beam_map, 0, 1, 1) / N)];
        [(beam_m(beam_map, 1, 0, 1) / N)  (beam_m(beam_map, 0, 1, 1) / N)  (beam_m(beam_map, 0, 0, 2) / N)];
    ]

    BeamMoments(S, M)
end