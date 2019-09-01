
"""
    RCMethod

Abstract type for nesting the various methods that can be used to perform a Reality Check. Subtypes are: \n
    RCBoot \n
The subtypes have entries in the help (?) menu.
"""
abstract type RCMethod end

"""
    RCBoot(data ; alpha::Float64=0.05, bootinput_kwargs...)

Method type for doing a Reality Check using a dependent bootstrap. A constructor
that takes the data and several keyword arguments is provided. The data refers
to the loss differences for each forecast relative to the basecase. Use ?rc for more detail.
Relevant keyword arguments are:
    alpha=0.05 <- The confidence level to use in the test \n
    kernelfunction=KernelEpanechnikov() <- The kernel function to use with HAC variance estimator. See ?hacvariance for more detail. \n
    bandwidth=-1 <- The bandwidth for HAC variance estimator. If bandwidth <= -1 then bandwidth is estimated using Politis (2003) "Adaptive Bandwidth Choice" \n
    blocklength=0.0 <- Block length to use with the bootstrap. Default of 0.0 implies
        the block length will be optimally estimated from the data use the method deemed
        most appropriate by the DependentBootstrap package (typically the selection procedure
        of Patton, Politis, and White (2009)). \n
    numresample=1000 <- Number of resamples to use when bootstrapping. \n
    bootmethod=:stationary <- Bootstrap methodology to use, where the default is the
        stationary bootstrap of Politis and Romano (1993) \n
See the DependentBootstrap package docs for more info on bootstrap input keyword arguments.
"""
struct RCBoot <: RCMethod
    alpha::Float64
	bootinput::BootInput
    function RCBoot(alpha::Float64, bootinput::BootInput)
        !(0.0 < alpha < 0.5) && error("Confidence level set to $(alpha) which is not on the (0, 0.5) interval")
        new(alpha, bootinput)
    end
end
RCBoot(data ; alpha::Float64=0.05, kwargs...)::RCBoot = RCBoot(alpha, BootInput(data, kwargs...))

"""
    RCTest(rejH0::Int, pvalue::Float64)

Output type from a Reality Check test.
The fields of this type follow: \n
    rejH0 <- true if the null is rejected, false otherwise
    pvalue <- p-value from the test
"""
struct RCTest
    rejH0::Bool
    pvalue::Float64
end
function Base.show(io::IO, a::RCBoot)
    println("Reality Check test results:")
    println("    Reject null hypothesis: $(a.rejH0)")
    println("    p-value: $(a.pvalue)")
end


"""
	rc(lD::Matrix{T}, method ; kwargs)
    rc(lD::Matrix{T} ; kwargs)

This function implements the test proposed in White (2000) "A Reality Check for Data Snooping" following the methodology in Hansen (2005). \n
Let x_0 denote a base-case forecast, x_k, k = 1, ..., K, denote K alternative forecasts, and y denote the forecast target.
Let L(., .) denote a loss function. The first argument of rc is a matrix where the kth column of the matrix is created by the operation: \n
L(x_k, y) - L(x_0, y) \n
Note that the forecast loss comes first and the base case loss comes second. This is the opposite to what is described in White's paper. \n
The second method argument determines which methodology to use. Currently, only RCBoot is available and if
this input type is provided, the keyword arguments are not needed.
Alternatively, the user can omit the second argument, and then any keyword arguments will be passed to the
RCBoot constructor. See ?RCBoot for more detail. The most relevant keyword arguments are:
    alpha=0.05 <- The confidence level to use in the test \n
    blocklength=0.0 <- Block length to use with the bootstrap. Default of 0.0 implies
        the block length will be optimally estimated from the data use the method deemed
        most appropriate by the DependentBootstrap package (typically the selection procedure
        of Patton, Politis, and White (2009)). \n
    numresample=1000 <- Number of resamples to use when bootstrapping. \n
    bootmethod=:stationary <- Bootstrap methodology to use, where the default is the
        stationary bootstrap of Politis and Romano (1993) \n
The output of a Reality Check test is of type RCTest. Use ?RCTest for more information.
"""
function rc(lD::Matrix{<:Number}, method::RCBoot)::RCTest
    lD *= -1 #White's loss differentials have base case first
	numObs = size(lD, 1)
	numModel = size(lD, 2)
	numResample = method.bootinput.numresample
	numObs < 2 && error("Number of observations = $(numObs) which is not enough to perform a reality check")
	numModel < 1 && error("Input dataset is empty")
	inds = dbootinds(Float64[], method.bootinput) #Bootstrap indices
    #Get mean loss differentials and bootstrapped mean loss differentials
	mld = Float64[ mean(view(lD, 1:numObs, k)) for k = 1:numModel ]
	mldBoot = Array{Float64}(undef, numModel, numResample)
	for j = 1:numResample
		for k = 1:numModel
			mldBoot[k, j] = mean(view(lD, 1:numObs, k)[inds[j]])
		end
	end
	#Get RC test statistic and bootstrapped density under the null
	v = maximum(sqrt(numObs) * mld)
	vBoot = maximum(sqrt(numObs) * (mldBoot .- mld), dims=1)
	#Calculate p-value and return (as vector)
	pVal = sum(vBoot .> v) / numResample
    pVal < method.alpha ? (rejH0 = true) : (rejH0 = false)
	return RCTest(rejH0, pVal)
end
#Keyword method
rc(lD::Matrix{<:Number} ; kwargs...)::RCTest = rc(lD, RCBoot(lD ; kwargs...))
function rc(lD::Matrix{<:Number}, method ; kwargs...)::RCTest
    method == :boot && return rc(lD, RCBoot(lD ; kwargs...))
    error("Invalid method: $(method)")
end
