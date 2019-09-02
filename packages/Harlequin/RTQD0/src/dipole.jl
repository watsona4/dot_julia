import StaticArrays, Printf
import LinearAlgebra: dot, cross

export DipoleParameters,
       doppler_temperature,
       dipole_temperature,
       SOLSYSDIR_ECL_THETA,
       SOLSYSDIR_ECL_PHI,
       SOLSYSSPEED_M_S,
       SPEED_OF_LIGHT_M_S,
       T_CMB,
       SPEED_OF_LIGHT_M_S,
       PLANCK_H_MKS,
       BOLTZMANN_K_MKS

# These data have been taken from Planck 2015 I, Table 1 (10.1051/0004-6361/201527101)
const SOLSYSDIR_ECL_THETA = 1.7656051330336222
const SOLSYSDIR_ECL_PHI = 2.9958842149922833
const SOLSYSSPEED_M_S = 370082.2332
const T_CMB = 2.72548

const SPEED_OF_LIGHT_M_S = 2.99792458e8
const PLANCK_H_MKS = 6.62606896e-34
const BOLTZMANN_K_MKS = 1.3806504e-23

@doc raw"""
This structure encodes the information needed to estimate the contribution of the
temperature of the CMB dipole caused by the motion of the Solar System with respect
to the CMB rest frame.

# Fields

- `solsysdir_theta_rad`: colatitude (in radians) of the dipole axis
- `solsysdir_phi_rad`: longitude (in radians) of the dipole axis
- `solsys_speed_m_s`: speed (in m/s) of the reference frame with respect to the
  CMB
- `solsys_velocity_m_s`: velocity 3-vector (in m/s) of the reference frame with
  respect to the CMB
- `tcmb_k`: thermodynamic temperature (in Kelvin) of the CMB

# Object creation

The simplest way to create a `DipoleParameters` object is to call the
constructor without arguments. In this case, the dipole axis will be provided in
Ecliptic coordinates, using the estimate by Planck 2015, and the best COBE
estimate for the CMB monopole temperature will be used. Otherwise, you can pass
any of the following keywords to set the parameters:

- `theta_rad` defaults to `SOLSYSDIR_ECL_THETA`
- `phi_rad` defaults to `SOLSYSDIR_ECL_PHI`
- `speed_m_s` defaults to `SOLSYSSPEED_M_S`
- `t_k` defaults to `T_CMB`

Here is an example where we produce a dipole that is 10% stronger than Planck's:

````julia
using Harlequin # hide
dip = DipoleParameters(speed_m_s = SOLSYS_SPEED_VEC_M_S * 1.10)
````
"""
struct DipoleParameters
    solsysdir_theta_rad::Float64
    solsysdir_phi_rad::Float64
    solsys_speed_m_s::Float64
    solsys_velocity_m_s::StaticArrays.StaticVector
    tcmb_k::Float64

    DipoleParameters(; 
        theta_rad = SOLSYSDIR_ECL_THETA, 
        phi_rad = SOLSYSDIR_ECL_PHI, 
        speed_m_s = SOLSYSSPEED_M_S, 
        t_k = T_CMB) = new(theta_rad, 
        phi_rad, 
        speed_m_s, 
        StaticArrays.SVector{3}(speed_m_s * [
            sin(theta_rad) * cos(phi_rad),
            sin(theta_rad) * sin(phi_rad),
            cos(theta_rad),
        ]),
        t_k)
end

function Base.show(io::IO, params::DipoleParameters)
    if get(io, :compact, false)
        Printf.@printf(io, "DipoleParameters([%.4f, %.4f, %.4f], %.4f)",
            params.solsys_velocity_m_s[1],
            params.solsys_velocity_m_s[2],
            params.solsys_velocity_m_s[3],
            params.tcmb_k,
        )
    else
        Printf.@printf(io, """DipoleParameters(
    theta_rad=%.6e,
    phi_rad=%.6e,
    speed_m_s=%.6e,
    t_k=%.6e,
)""",
            params.solsysdir_theta_rad,
            params.solsysdir_phi_rad,
            params.solsys_speed_m_s,
            params.tcmb_k,
        )
    end
end

function doppler_temperature(velocity_m_s, dir, tcmb_k)
    betavec = velocity_m_s / SPEED_OF_LIGHT_M_S
    gamma = 1 / sqrt(1 - dot(betavec, betavec))
    
    tcmb_k * (1 / (gamma * (1 - dot(betavec, dir))) - 1)
end

function doppler_temperature(velocity_m_s,
    dir,
    tcmb_k, freq_hz,
)
    fact = PLANCK_H_MKS * freq_hz / (BOLTZMANN_K_MKS * tcmb_k)
    expfact = exp(fact)
    q = (fact / 2) * (expfact + 1) / (expfact - 1)

    betavec = velocity_m_s / SPEED_OF_LIGHT_M_S
    dotprod = dot(betavec, dir)
    tcmb_k * (dotprod + q * dotprod^2)
end

@doc raw"""
    doppler_temperature(velocity_m_s, dir, tcmb_k)
    doppler_temperature(velocity_m_s, dir, tcmb_k, freq_hz)

Compute the temperature caused by the motion by `velocity_m_s` (a 3-vector, in
m/s) through the Doppler effect. If `freq_hz` is specified, the computation
includes quadrupolar relativistic corrections.

# See also

If you need to compute the solar dipole caused by the motion of the Solar System
with respect to the CMB rest frame, it is easier to use
[`dipole_temperature`](@ref).

# Example

"""
doppler_temperature

################################################################################

function dipole_temperature(dir;
    params::DipoleParameters = DipoleParameters(),)
    doppler_temperature(params.solsys_velocity_m_s, dir, params.tcmb_k)
end

function dipole_temperature(dir,
    freq_hz::Number; 
    params::DipoleParameters = DipoleParameters(),)
    doppler_temperature(params.solsys_velocity_m_s, dir, params.tcmb_k, freq_hz)
end

@doc raw"""
    dipole_temperature(dir; params::DipoleParameters = DipoleParameters())
    dipole_temperature(dir, freq_hz; params::DipoleParameters = DipoleParameters())
    
Compute the temperature of the dipole along the direction `dir`, which should be
a 3 - element array containing the XYZ components of the pointing vector.The
vector must be expressed in the same coordinates as the vector used to specify
the dipole in `params`, which is an object of type `DipoleParameters`.(Hint:if
you created this object calling the constructor without arguments, as in
`DipoleParameters()`, Ecliptic coordinates will be used.)

If `freq_hz` is specified, a relativistic frequency - dependent correction is
applied.

# See also

If you need to compute the temperature caused by any other kinetic component
(e.g., the orbital dipole caused by the motion of the spacecraft), use
[`doppler_temperature`](@ref).

# Example

````julia
julia> dipole_temperature([0, 0, 1])
-0.0006532169921239991

julia> dipole_temperature([0, 0, 1], params=DipoleParameters(speed_m_s=371e3))
-0.0006548416782232279

julia> dipole_temperature([0, 0, 1], 30e9, params=DipoleParameters(speed_m_s=371e3))
-0.0006527515338213527
````
"""
dipole_temperature
