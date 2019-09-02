# This file is part of Kpax3. License is MIT.

function logmarglik(y::Vector{Float64},
                    n::Real,
                    α::Vector{Float64},
                    β::Vector{Float64})
  SpecialFunctions.lbeta.(α .+ y, β .- y .+ n) .- SpecialFunctions.lbeta.(α, β)
end

function logmarglik(y::Real,
                    n::Real,
                    α::Real,
                    β::Real)
  SpecialFunctions.lbeta(α + y, β + n - y) - SpecialFunctions.lbeta(α, β)
end

function logcondmarglik(x::Vector{UInt8},
                        y::Vector{Float64},
                        n::Real,
                        α::Vector{Float64},
                        β::Vector{Float64})
  float(x) .* log.(α .+ y) .+
  (one(Float64) .- float(x)) .* log.(β .- y .+ n) .-
  log.(α .+ β .+ n)
end

function logcondmarglik(x::Real,
                        y::Real,
                        n::Real,
                        α::Real,
                        β::Real)
  (x * log(α + y) + (one(x) - x) * log(β + n - y) - log(α + β + n))::Float64
end

function marglik(y::Vector{Float64},
                 n::Real,
                 α::Vector{Float64},
                 β::Vector{Float64})
  exp.(logmarglik(y, n, α, β))
end

function marglik(y::Real,
                 n::Real,
                 α::Real,
                 β::Real)
  exp(logmarglik(y, n, α, β))
end

function condmarglik(x::Vector{UInt8},
                     y::Vector{Float64},
                     n::Real,
                     α::Vector{Float64},
                     β::Vector{Float64})
  exp.(logcondmarglik(x, y, n, α, β))
end

function condmarglik(x::Real,
                     y::Real,
                     n::Real,
                     α::Real,
                     β::Real)
  exp(logcondmarglik(x, y, n, α, β))
end
