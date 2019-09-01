
#Kernel functions for use with hacvariance estimator
abstract type KernelFunction end
struct KernelEpanechnikov <: KernelFunction ; end
struct KernelGaussian <: KernelFunction ; end
struct KernelUniform <: KernelFunction ; end
struct KernelBartlett <: KernelFunction ; end
const KERNEL_FUNCTION_DICT = Dict{Symbol,KernelFunction}(
	:epanechnikov => KernelEpanechnikov(),
	:gaussian => KernelGaussian(),
	:uniform => KernelUniform(),
	:bartlett => KernelBartlett()
)::Dict{Symbol,KernelFunction}
(get_kernel_type(kf::Tk)::Tk) where {Tk<:KernelFunction} = kf
(get_kernel_type(kf::Symbol)) = get_kernel_type(KERNEL_FUNCTION_DICT[kf])
(get_kernel_type(kf::String)) = get_kernel_type(Symbol(kf))
(get_kernel_type(kf)) = error("Input type $(typeof(kf)) not able to be converted to kernel function type: $(kf)")
kernel_eval(x::Number, bw::Number, kf::KernelEpanechnikov)::Float64 = (-1.0 <= x / bw <= 1.0) ? (0.75 / bw) * (1 - (x^2 / bw^2)) : 0.0
kernel_eval(x::Number, bw::Number, kf::KernelGaussian)::Float64 = (1 / bw) * (1 / sqrt(2*pi)) * exp(-1 * (x^2 / (2 * bw^2)))
kernel_eval(x::Number, bw::Number, kf::KernelUniform)::Float64 = (-1.0 <= x / bw <= 1.0) ? 1 / 2*bw : 0.0
kernel_eval(x::Number, bw::Number, kf::KernelBartlett)::Float64 = (-1.0 <= x / bw <= 1.0) ? (1 - abs(x / bw)) : 0.0


"""
	hacvariance{T<:Number}(x::AbstractVector{T} ; kf::Symbol=:epanechnikov, bw::Int=-1)::Tuple{Float64, Int}

Get the heteroskedasticity and autocorrelation consistent variance estimator of data vector x.
The function has the following keyword arguments:
	kf <- Kernel function used in estimator. Valid values are :epanechnikov, :gaussian, :uniform, :bartlett
	bw <- Bandwidth used in estimator. If <= -1, then estimate bandwidth using Politis (2003) "Adaptive Bandwidth Choice"
"""
function hacvariance(x::AbstractVector{<:Number}, kf::Tk, bw::Int)::Tuple{Float64, Int} where {Tk<:KernelFunction}
	if bw <= -1 ; (bw, v, xCov) = DependentBootstrap.bandwidth_politis_2003(x)
	else ; (v, xCov) = (var(x), Float64[]) ; end
	length(xCov) < bw && append!(xCov, autocov(x, length(xCov)+1:bw)) #Get any additional autocovariances that we might need
	kernelAdjTerm = 1 / kernel_eval(0.0, bw, kf) #Used to scale kernel functions that don't satisfy k(0) = 1
	for m = 1:bw
		v += 2 * kernelAdjTerm * kernel_eval(m, bw, kf) * xCov[m]
	end
	return (max(v, 0.0), bw)
end
hacvariance(x::AbstractVector{<:Number} ; kf=KernelEpanechnikov(), bw::Int=-1)::Tuple{Float64, Int} = hacvariance(x, get_kernel_type(kf), bw)
