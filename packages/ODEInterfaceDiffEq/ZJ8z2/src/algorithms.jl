# ODEInterface.jl Algorithms

abstract type ODEInterfaceAlgorithm <: DiffEqBase.AbstractODEAlgorithm end
abstract type ODEInterfaceImplicitAlgorithm <: ODEInterfaceAlgorithm end
abstract type ODEInterfaceExplicitAlgroithm <: ODEInterfaceAlgorithm end
struct dopri5 <: ODEInterfaceExplicitAlgroithm end
struct dop853 <: ODEInterfaceExplicitAlgroithm end
struct odex <: ODEInterfaceExplicitAlgroithm end
struct seulex{T} <: ODEInterfaceImplicitAlgorithm
    jac_lower::T
    jac_upper::T
end
struct radau{T} <: ODEInterfaceImplicitAlgorithm
    jac_lower::T
    jac_upper::T
end
struct radau5{T} <: ODEInterfaceImplicitAlgorithm
    jac_lower::T
    jac_upper::T
end
struct rodas{T} <: ODEInterfaceImplicitAlgorithm
    jac_lower::T
    jac_upper::T
end
struct ddeabm <: ODEInterfaceExplicitAlgroithm end
struct ddebdf{T} <: ODEInterfaceImplicitAlgorithm
    jac_lower::T
    jac_upper::T
end

seulex(;jac_lower=nothing,jac_upper=nothing) = seulex(jac_lower,jac_upper)
radau(;jac_lower=nothing,jac_upper=nothing) = radau(jac_lower,jac_upper)
radau5(;jac_lower=nothing,jac_upper=nothing) = radau5(jac_lower,jac_upper)
rodas(;jac_lower=nothing,jac_upper=nothing) = rodas(jac_lower,jac_upper)
ddebdf(;jac_lower=nothing,jac_upper=nothing) = ddebdf(jac_lower,jac_upper)
