# ------------------------------------------------------------------
# Licensed under the ISC License. See LICENCE in the project root.
# ------------------------------------------------------------------

module DirectGaussianSimulation

using GeoStatsBase
import GeoStatsBase: preprocess, solve_single

using Variography
using LinearAlgebra

export DirectGaussSim

"""
    DirectGaussSim(var₁=>param₁, var₂=>param₂, ...)

Direct Gaussian simulation (a.k.a. LU simulation).

## Parameters

* `variogram` - theoretical variogram (default to GaussianVariogram())

### References

Alabert 1987. *The practice of fast conditional simulations through the
LU decomposition of the covariance matrix.*
"""
@simsolver DirectGaussSim begin
  @param variogram = GaussianVariogram()
  @param mean = nothing
end

function preprocess(problem::SimulationProblem, solver::DirectGaussSim)
  # retrieve problem info
  pdata = data(problem)
  pdomain = domain(problem)

  # result of preprocessing
  preproc = Dict{Symbol,Tuple}()

  for (var, V) in variables(problem)
    # get user parameters
    if var ∈ keys(solver.params)
      varparams = solver.params[var]
    else
      varparams = DirectGaussSimParam()
    end

    # determine variogram model
    γ = varparams.variogram

    # check stationarity
    @assert isstationary(γ) "variogram model must be stationary"

    # retrieve data locations in domain and data values
    datalocs = Vector{Int}()
    z₁ = Vector{V}()
    for (loc, dataloc) in datamap(problem, var)
      push!(datalocs, loc)
      push!(z₁, value(pdata, dataloc, var))
    end

    # retrieve simulation locations
    simlocs = [l for l in 1:npoints(pdomain) if l ∉ datalocs]

    # covariance between simulation locations
    C₂₂ = sill(γ) .- pairwise(γ, pdomain, simlocs)

    if isempty(datalocs)
      d₂  = zero(V)
      L₂₂ = cholesky(Symmetric(C₂₂)).L
    else
      # covariance beween data locations
      C₁₁ = sill(γ) .- pairwise(γ, pdomain, datalocs)
      C₁₂ = sill(γ) .- pairwise(γ, pdomain, datalocs, simlocs)

      L₁₁ = cholesky(Symmetric(C₁₁)).L
      B₁₂ = L₁₁ \ C₁₂
      A₂₁ = B₁₂'

      d₂ = A₂₁ * (L₁₁ \ z₁)
      L₂₂ = cholesky(Symmetric(C₂₂ - A₂₁*B₁₂)).L
    end

    if !isnothing(varparams.mean) && !isempty(datalocs)
      @warn "mean can only be specified in unconditional simulation"
    end

    # mean for unconditional simulation
    μ = isnothing(varparams.mean) ? zero(V) : varparams.mean

    preproc[var] = (z₁, d₂, L₂₂, μ, datalocs, simlocs)
  end

  preproc
end

function solve_single(problem::SimulationProblem, var::Symbol,
                      solver::DirectGaussSim, preproc)
  # retrieve problem info
  pdomain = domain(problem)

  # unpack preprocessed parameters
  z₁, d₂, L₂₂, μ, datalocs, simlocs = preproc[var]

  # allocate memory for result
  realization = Vector{eltype(z₁)}(undef, npoints(pdomain))

  # set hard data
  realization[datalocs] = z₁

  # simulate the rest
  w₂ = randn(size(L₂₂, 2))
  y₂ = d₂ .+ L₂₂*w₂
  realization[simlocs] = y₂

  # adjust mean in case of unconditional simulation
  isempty(datalocs) && (realization .+= μ)

  realization
end

end
