"""
# module NonlinearFitting



# Examples

```jldoctest
julia>
```
"""
module NonlinearFitting

using LsqFit: curve_fit
using Transducers: collect, NotA, DropLast

using EquationsOfState.Collections

export fit_energy,
    fit_pressure,
    fit_bulk_modulus,
    get_fitting_parameters

convert_eltype(T::Type, a) = map(x -> convert(T, x), a)

get_fitting_parameters(eos::EquationOfState) = collect(NotA(NonFittingParameter), get_parameters(eos))

function fit_energy(eos::EquationOfState{T}, xdata::AbstractVector{T}, ydata::AbstractVector{T}; kwargs...) where {T <: AbstractFloat}
    function model(x, p)
        f = collect(DropLast(1), p) |> typeof(eos) |> eval_energy
        f.(x, last(p))
    end
    curve_fit(model, xdata, ydata, push!(get_fitting_parameters(eos), minimum(ydata)); kwargs...)
end
function fit_energy(eos::EquationOfState, xdata::AbstractVector, ydata::AbstractVector; kwargs...)
    T = promote_type(eltype(eos), eltype(xdata), eltype(ydata), Float64)
    fit_energy(convert_eltype(T, eos), convert_eltype(T, xdata), convert_eltype(T, ydata); kwargs...)
end

create_model(eos::EquationOfState) = (x::AbstractVector, p::AbstractVector) -> map(p |> typeof(eos) |> eval_pressure, x)
create_model(eos::Holzapfel) = (x::AbstractVector, p::AbstractVector) -> map(push!(p, eos.z) |> typeof(eos) |> eval_pressure, x)

function fit_pressure(eos::EquationOfState{T}, xdata::AbstractVector{T}, ydata::AbstractVector{T}; kwargs...) where {T <: AbstractFloat}
    model = create_model(eos)
    curve_fit(model, xdata, ydata, get_fitting_parameters(eos); kwargs...)
end
function fit_pressure(eos::EquationOfState, xdata::AbstractVector, ydata::AbstractVector; kwargs...)
    T = promote_type(eltype(eos), eltype(xdata), eltype(ydata), Float64)
    fit_pressure(convert_eltype(T, eos), convert_eltype(T, xdata), convert_eltype(T, ydata); kwargs...)
end

function fit_bulk_modulus(eos::EquationOfState{T}, xdata::AbstractVector{T}, ydata::AbstractVector{T}; kwargs...) where {T <: AbstractFloat}
    model(x, p) = map(p |> typeof(eos) |> eval_bulk_modulus, x)
    curve_fit(model, xdata, ydata, get_fitting_parameters(eos); kwargs...)
end
function fit_bulk_modulus(eos::EquationOfState, xdata::AbstractVector, ydata::AbstractVector; kwargs...)
    T = promote_type(eltype(eos), eltype(xdata), eltype(ydata), Float64)
    fit_bulk_modulus(convert_eltype(T, eos), convert_eltype(T, xdata), convert_eltype(T, ydata); kwargs...)
end

end