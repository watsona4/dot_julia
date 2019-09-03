# Discretization methods as structures
# Full Discretization
abstract type DiscretizationMethod{fT} end
struct FullDiscretization{fT} <: DiscretizationMethod{fT} 
    Δt::fT; # Time resolution of the discretisation
end
terms(::FullDiscretization) = 1
methodorder(::FullDiscretization) = 0

# Semi-Discretization
abstract type SemiDiscretizationMethodOrder end
struct NumericSD{N} <: SemiDiscretizationMethodOrder end
struct AnalyticZero <: SemiDiscretizationMethodOrder end
struct AnalyticZeroImproved <: SemiDiscretizationMethodOrder end
struct AnalyticFirst <: SemiDiscretizationMethodOrder end

struct SemiDiscretization{T,fT<:AbstractFloat} <: DiscretizationMethod{fT}
    Δt::fT; # Time resolution of the discretisation
end
SemiDiscretization(Δt::fT) where fT<:AbstractFloat = SemiDiscretization{NumericSD{1},fT}(Δt)
SemiDiscretization(SDorder::Int,Δt::fT) where fT<:AbstractFloat = SemiDiscretization{NumericSD{SDorder},fT}(Δt)
# n-th order semi discretisation for analytical calculation of the submatrices
SemiDiscretization(SDorder::Type{<:SemiDiscretizationMethodOrder},Δt::fT) where fT<:AbstractFloat = SemiDiscretization{SDorder,fT}(Δt)

_terms(::Type{AnalyticZero}) = 1
_terms(::Type{AnalyticZeroImproved}) = 2
_terms(::Type{AnalyticFirst}) = 2
_terms(::Type{NumericSD{N}}) where N = N+1

_methodorder(::Type{AnalyticZero}) = 0
_methodorder(::Type{AnalyticZeroImproved}) = 0
_methodorder(::Type{AnalyticFirst}) = 1
_methodorder(::Type{NumericSD{N}}) where N = N

terms(::SemiDiscretization{T,fT}) where {T<:SemiDiscretizationMethodOrder,fT} = _terms(T)
methodorder(::SemiDiscretization{T,fT}) where {T<:SemiDiscretizationMethodOrder,fT} = _methodorder(T)
# n-th order semi discretisation for numerical calculation of the submatrices