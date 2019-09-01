
"""
    SPAMethod

Abstract type for nesting the various methods that can be used to perform an SPA test. Subtypes are: \n
    SPABoot \n
The subtypes have entries in the help (?) menu.
"""
abstract type SPAMethod end

"""
    SPABoot(data ; alpha, kernelfunction, bandwidth, bootinput_kwargs...)

Method type for doing an SPA test using a dependent bootstrap. A constructor
that takes the data and several keyword arguments is provided. The data refers
to the loss differences for each forecast relative to the basecase. Use ?spa for more detail.
Relevant keyword arguments are: \n
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
Note, see the DependentBootstrap docs for more information on valid keyword arguments
for the BootInput constructor.
"""
struct SPABoot{Tk<:KernelFunction} <: SPAMethod
	alpha::Float64
	bootinput::BootInput
	kernelfunction::Tk
	bandwidth::Int
	function SPABoot(alpha::Float64, bootinput::BootInput, kernelfunction::Tk, bandwidth::Int) where {Tk<:KernelFunction}
		!(0.0 < alpha < 0.5) && error("Confidence level set to $(alpha) which is not on the (0, 0.5) interval")
		new{Tk}(alpha, bootinput, kernelfunction, bandwidth)
	end
end
function SPABoot(data ; alpha::Float64=0.05, kernelfunction=KernelEpanechnikov(), bandwidth::Int=-1, kwargs...)
    return SPABoot(alpha, BootInput(data, flevel1=mean, kwargs...), get_kernel_type(kernelfunction), bandwidth)
end

"""
	SPATest(rejH0::Int, mu_u::Vector{Float64}, mu_c::Vector{Float64}, mu_l::Vector{Float64}, pvalue_u::Float64, pvalue_c::Float64, pvalue_l::Float64, pvalue::Float64, teststat::Float64)

Output type for an SPA test proposed in Hansen (2005) "A Test for Superior Predictive Ability". The names of the fields
for this type follow those in the referenced paper, so see that paper for more detail. The fields of this type follow: \n
	rejH0 <- true if the null is rejected, false otherwise
	mu_u <- mu associated with upper bound on threshold rate
	mu_c <- Recommended mu
	mu_l <- mu associated with lower bound on threshold rate
	pvalue_u <- pvalue associated with mu_u
	pvalue_c <- pvalue assoicated with mu_c
	pvalue_l <- pvalue associated with mu_l
	pvalueauto <- Recommended p-value (usually pvalue_c except in rare situations where this method can fail)
	teststat::Float64 <- SPA test statistic (look for tSPA in source paper) \n
Note the different mu variables, {u, c, l} are described in the referenced article on p370-371. \n
Most users will just be interested in the field pvalueauto.
"""
struct SPATest
	rejH0::Bool
	mu_u::Vector{Float64} #mu associated with upper bound on threshold rate
	mu_c::Vector{Float64} #Recommended mu
	mu_l::Vector{Float64} #mu associated with lower bound on threshold rate
	pvalue_u::Float64 #pvalue associated with mu_u
	pvalue_c::Float64 #pvalue assoicated with mu_c
	pvalue_l::Float64 #pvalue associated with mu_l
	pvalueauto::Float64 #Recommended p-value (usually pvalue_c except in rare situations)
	teststat::Float64 #SPA test statistic
end
function Base.show(io::IO, a::SPATest)
    println("SPA test results:")
    println("    test stat: $(a.teststat)")
    println("    pvalue (u): $(a.pvalue_u)")
    println("    pvalue (c): $(a.pvalue_c)")
    println("    pvalue (l): $(a.pvalue_l)")
end


"""
	spa{T<:Number}(lossDiff::Matrix{T}, method ; kwargs...)::SPATest
	spa{T<:Number}(lossDiff::Matrix{T} ; kwargs...)

This function implements the SPA test proposed in Hansen (2005) "A Test for Superior Predictive Ability". \n
Let x_0 denote a base-case forecast, x_k, k = 1, ..., K, denote K alternative forecasts, and y denote the forecast target.
Let L(., .) denote a loss function. The first argument of spa is a matrix where the kth column of the matrix is created by the operation: \n
L(x_k, y) - L(x_0, y) \n
Note that the forecast loss comes first and the base case loss comes second. This is the opposite to what is described in Hansen's paper. \n
The second method argument determines which methodology to use. Currently, only SPABoot is available and if
this input type is provided, the keyword arguments are not needed.
Alternatively, the user can omit the second argument, and then any keyword arguments will be passed to the
SPABoot constructor. See ?SPABoot for more detail. The most relevant keyword arguments are:
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
The output of an SPA test is of type SPATest. Use ?SPATest for more information. \n
Note, Hansen suggests using the Stationary Bootstrap implied HAC variance estimator, which is not currently supported in this package.
However, note that any consistent HAC estimator is valid and in many cases may be preferred.
"""
function spa(lD::Matrix{<:Number}, method::SPABoot)::SPATest
	lD = -1.0*lD	#Hansen's loss differentials have base case first
	numObs = size(lD, 1)
	numModel = size(lD, 2)
	numResample = method.bootinput.numresample
	numObs < 2 && error("Number of observations = $(numObs) which is not enough to perform a reality check")
	numModel < 1 && error("Input dataset is empty")
	inds = dbootinds(Float64[], method.bootinput) #Get bootstrap indices
	#Get hac variance estimators
	wSqVec = Array{Float64}(undef, numModel)
	for k = 1:numModel
		(wSqVec[k], _) = hacvariance(lD[:, k], kf=method.kernelfunction, bw=method.bandwidth)
		wSqVec[k] <= 0.0 && (wSqVec[k] = nextfloat(0.0))
	end
	wInv = Float64[ 1 / sqrt(wSqVec[k]) for k = 1:numModel ]
	#Get bootstrapped mean loss differentials
	mldBoot = Array{Float64}(undef, numModel, numResample)
	for j = 1:numResample
		for k = 1:numModel
			mldBoot[k, j] = mean(view(lD, 1:numObs, k)[inds[j]])
		end
	end
	#Get mu definitions
	mu_u = Float64[ mean(view(lD, 1:numObs, k)) for k = 1:numModel ]
	mu_l = Float64[ max(mu_u[k], 0) for k = 1:numModel ]
	multTerm_mu_c = (1/numObs) * 2 * log(log(numObs))
	mu_c = Float64[ (mu_u[k] >= -1 * sqrt(multTerm_mu_c * wSqVec[k])) * mu_u[k] for k = 1:numModel ]
	#Get test statistic
	tSPA = maximum([ max(sqrt(numObs) * mu_u[k] * wInv[k], 0) for k = 1:numModel ])
	#Get p-values for each mu term
	muVecVec = Vector{Float64}[mu_u, mu_c, mu_l] #Order must be u, c, l
	pValVec = Array{Float64}(undef, length(muVecVec))
	for q = 1:length(muVecVec)
		z = sqrt(numObs) * (wInv .* (mldBoot .- muVecVec[q]))
		tSPAmu = Float64[ max(0, maximum(view(z, 1:numModel, i))) for i = 1:numResample ]
		pValVec[q] = (1 / numResample) * sum(tSPAmu .> tSPA)
	end
	any(mu_c .!= 0.0) ? (pvalueAuto = pValVec[2]) : (pvalueAuto = pValVec[3]) #Ad hoc rule as to which p-value is likely to be the most reliable
	pvalueAuto < method.alpha ? (rejH0 = true) : (rejH0 = false)
	spaTest = SPATest(rejH0, mu_u, mu_c, mu_l, pValVec[1], pValVec[2], pValVec[3], pvalueAuto, tSPA)
	return(spaTest)
end
#Keyword wrapper
spa(lossDiff::Matrix{<:Number} ; kwargs...)::SPATest = spa(lossDiff, SPABoot(lossDiff ; kwargs...))
