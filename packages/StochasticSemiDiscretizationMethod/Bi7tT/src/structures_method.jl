abstract type ItoIsometryMethod{K} <: AbstractVector{Float64} end
struct Trapezoidal{K} <: ItoIsometryMethod{K}
    dt::Float64
end
Trapezoidal(k,method::DiscretizationMethod) = Trapezoidal{k+1}(method.Δt/k)
Base.size(iim::Trapezoidal{k}) where k = (k,)
Base.getindex(iim::Trapezoidal{k},idx::Integer) where k = idx < k && idx > 1 ? 1.0 : 0.5
Base.getindex(iim::Trapezoidal,idxs::Vector{<:Integer}) = getindex.(Ref(iim),idxs)

# # Container for the integrand in the ito integral
# struct stIntFun{T,k} <: AbstractVector{T}
#     f::AbstractVector{T}
# end
# stIntFun(f::AbstractVector) = stIntFun{eltype(f),length(f)}(f)

# Base.size(stif::stIntFun{T,k}) where {T,k}= (k,)
# Base.getindex(stif::stIntFun{T,k},idx...) where k = stif.f[idx...]
# Base.setindex!(stif::stIntFun{T,k},X,idx...) where k = setindex!(stif.f,X,idx...)

# Base.zero(::Type{stIntFun{T,k}}) where {T,k} = stIntFun(zeros(T,k))

# function (iim::Trapezoidal)(v1,v2)
#     sum(v1[k]*v2[k]*tw for (k,tw) in enumerate(iim))
# end
