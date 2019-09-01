"""
# module LinearFitting



# Examples

```jldoctest
julia>
```
"""
module LinearFitting

using LinearAlgebra: dot
using Polynomials: polyder, polyfit, degree, coeffs, Poly
using Rematch

using EquationsOfState.FiniteStrains

export energy_strain_expansion,
    energy_strain_derivative,
    strain_volume_derivative,
    energy_volume_expansion,
    energy_volume_derivatives,
    energy_volume_derivative_at_order

energy_strain_expansion(f::Vector{Float64}, e::Vector{Float64}, n::Int)::Poly = polyfit(f, e, n)

energy_strain_derivative(p::Poly, m::Int)::Poly = polyder(p, m)

function strain_volume_derivative(f::EulerianStrain, v::Float64, m::Int)::Float64
    m == 1 && return -1 / 3 / v * (f.v0 / v)^(2 / 3)
    -(3 * m + 2) / (3 * v) * strain_volume_derivative(f, v, m - 1)
end
function strain_volume_derivative(f::LagrangianStrain, v::Float64, m::Int)::Float64
    m == 1 && return -1 / 3 / v * (v / f.v0)^(2 / 3)
    -(3 * m - 2) / (3 * v) * strain_volume_derivative(f, v, m - 1)
end
function strain_volume_derivative(f::NaturalStrain, v::Float64, m::Int)::Float64
    m == 1 && return 1 / 3 / v
    -m / v * strain_volume_derivative(f, v, m - 1)
end
function strain_volume_derivative(f::InfinitesimalStrain, v::Float64, m::Int)::Float64
    m == 1 && return (1 - get_strain(f, v))^4 / 3 / f.v0
    -(3 * m + 1) / 3 / v * strain_volume_derivative(f, v, m - 1)
end

function energy_volume_expansion(f::FiniteStrain, v::Float64, p::Poly, highest_order::Int=degree(p))
    # The zeroth order value plus values from the first to the ``highest_order`.
    p(v) + dot(energy_volume_derivatives(f, v, p, highest_order), get_strain(f, v).^collect(1:highest_order))
end

function energy_volume_derivatives(f::FiniteStrain, v::Float64, p::Poly, highest_order::Int)
    0 ≤ highest_order ≤ degree(p) ? (x = 1:highest_order) : throw(DomainError("The `highest_order` must be within 0 to $(degree(p))!"))
    strain_derivatives::Vector{Float64} = map(m -> strain_volume_derivative(f, v, m), x)
    energy_derivatives::Vector{Float64} = map(f -> f(v), map(m -> energy_strain_derivative(p, m), x))
    map(m -> energy_volume_derivative_at_order(m)(strain_derivatives, energy_derivatives), x)
end

function energy_volume_derivative_at_order(m::Int)::Function
    function (f::Vector{Float64}, e::Vector{Float64})
        @match m begin
            1 => e[1] * f[1]
            2 => e[2] * f[1]^2 + e[1] * f[1]
            3 => e[3] * f[1]^3 + 3 * f[1] * f[2] * e[2] + e[1] * f[3]
            4 => e[4] * f[1]^4 + 6 * f[1]^2 * f[2] * e[3] + (4 * f[1] * f[3] + 3 * f[3]^2) * e[2] + e[1] * f[3]
            _ => error("Expansion is not defined at order = $(m)!")
        end
    end
end

end
