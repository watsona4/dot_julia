
"""
    DMMethod

Abstract type for nesting the various methods that can be used to perform Diebold-Mariano tests. Subtypes are: \n
    DMHAC
    DMBoot \n
The subtypes have entries in the help (?) menu.
"""
abstract type DMMethod end

"""
    DMHAC(data ; alpha::Float64=0.05, kernelfunction, bandwidth::Int=-1)

Method type for doing a Diebold-Mariano test using a HAC variance estimator. A
constructor that takes the data and three keyword arguments is provided. Relevant
keyword arguments are: \n
    alpha <- The confidence level for the test \n
    kernelfunction <- Kernel function to use in HAC variance estimator. Valid values are
        KernelEpanechnikov(), KernelGaussian(), KernelUniform(), KernelBartlett(). You can
        also :epanechnikov, :gaussian, :uniform, :bartlett, or String variants of these symbols. \n
    bandwidth <- Bandwidth to use in HAC variance estimator (set less than or equal to -1 to estimate bandwidth using Politis (2003) "Adaptive Bandwidth Choice") \n
"""
struct DMHAC{Tk<:KernelFunction} <: DMMethod
    alpha::Float64
    kernelfunction::Tk
    bandwidth::Int
    function DMHAC(alpha::Float64, kernelfunction::Tk, bandwidth::Int) where {Tk<:KernelFunction}
        !(0.0 < alpha < 0.5) && error("Confidence level set to $(alpha) which is not on the (0, 0.5) interval")
        new{Tk}(alpha, kernelfunction, bandwidth)
    end
end
DMHAC( ; alpha::Float64=0.05, kernelfunction=KernelEpanechnikov(), bandwidth::Int=-1) = DMHAC(alpha, get_kernel_type(kernelfunction), bandwidth)
DMHAC(data ; alpha::Float64=0.05, kernelfunction=KernelEpanechnikov(), bandwidth::Int=-1) = DMHAC(alpha, get_kernel_type(kernelfunction), bandwidth) #Superfluous but included for consistency

"""
    DMBoot(data ; alpha, bootinput_kwargs...)

Method type for doing a Diebold-Mariano test using a dependent bootstrap. A constructor
that takes the data and several keyword arguments is provided. Relevant keyword arguments are: \n
    alpha=0.05 <- The confidence level to use in the test \n
    blocklength=0.0 <- Block length to use with the bootstrap. Default of 0.0 implies
        the block length will be optimally estimated from the data use the method deemed
        most appropriate by the DependentBootstrap package (typically the selection procedure
        of Patton, Politis, and White (2009)). \n
    numresample=1000 <- Number of resamples to use when bootstrapping. \n
    bootmethod=:stationary <- Bootstrap methodology to use, where the default is the
        stationary bootstrap of Politis and Romano (1993) \n
See the DependentBootstrap package docs for more info on bootstrap input keyword arguments.
"""
struct DMBoot <: DMMethod
    alpha::Float64
    bootinput::BootInput
    function DMBoot(alpha::Float64, bootinput::BootInput)
        !(0.0 < alpha < 0.5) && error("Confidence level set to $(alpha) which is not on the (0, 0.5) interval")
        bootinput.flevel1 != mean && error("flevel1 field in BootInput must be set equal to mean. Please use the keyword constructor for DMBoot as this automatically enforces this behaviour: $(bootinput.flevel1)")
        new(alpha, bootinput)
    end
end
DMBoot(data ; alpha::Float64=0.05, kwargs...) = DMBoot(alpha, BootInput(data ; flevel1=mean, kwargs...))

"""
    DMTest(rejH0::Int, pvalue::Float64, bestinput::Int, teststat::Float64, dmmethod::DMMethod)

Output type for a Diebold-Mariano test. A description of the fields follows: \n
    rejH0 <- true if the null is rejected, false otherwise
    pvalue <- p-value from the test
    bestinput <- 1 if forecast 1 is more accurate, and 2 if forecast 2 is more accurate. See ?dm for definition of forecast 1 versus 2.
    teststat <- If dmmethod == :hac then is the mean of loss difference scaled by HAC variance
                If dmmethod == :boot then is the mean of loss difference
    dmmethod <- Diebold-Mariano method used in the test. See ?DMMethod for more detail.
"""
struct DMTest
    rejH0::Bool
    pvalue::Float64
    bestinput::Int
    teststat::Float64
    dmmethod::DMMethod
    DMTest(rejH0::Bool, pvalue::Float64, bestinput::Int, teststat::Float64, dmmethod::DMMethod) = new(rejH0, pvalue, bestinput, teststat, dmmethod)
end
function Base.show(io::IO, a::DMTest)
    println(io, "Diebold-Mariano test results:")
    println(io, "    Reject null of equal predictive ability: $(a.rejH0)")
    println(io, "    p-value: $(a.pvalue)")
    println(io, "    Preferred forecast: $(a.bestinput)")
end

"""
    dm(lossdiff::Vector{<:Number}, dmmethod ; kwargs...)

This function implements the test proposed in Diebold, Mariano (1995) "Comparing Predictive Accuracy". \n
Let x_1 denote forecast 1, x_2 denote forecast 2, and let y denote the forecast target. Let L(., .) denote a loss function.
Then the first argument lossdiff is assumed to be a vector created by the following operation: \n
L(x_1, y) - L(x_2, y) \n
The second argument, dmmethod, can be an explicit method type, currently DMHAC or DMBoot,
(see ?DMHAC and ?DMBoot for more detail), in which case the keyword arguments are not needed. \n
Alternatively, dmmethod can be set to the Symbol :hac or :boot, depending on whether the user
wants to use the HAC method or the bootstrap method. In this instance, the keyword arguments
provided will be passed on to DMHAC or DMBoot constructors (see ?DMHAC and ?DMBoot for more detail). \n
Finally, the second argument can be omitted entirely, in which case the method will default to
the default bootstrap method, which is the stationary bootstrap of Politis and Romano (1993) with
block length estimated followed Patton, Politis, and White (2009). \n
The output of a Diebold-Mariano test is of type DMTest. Use ?DMTest for more information.
"""
function dm(lossDiff::Vector{<:Number}, method::DMHAC)::DMTest
	length(lossDiff) < 2 && error("Input data vector has length of $(length(lossDiff))")
	m = mean(lossDiff)
	(v, _) = hacvariance(lossDiff, kf=method.kernelfunction, bw=method.bandwidth)
	testStat = m / sqrt(v / length(lossDiff))
	pVal = pvaluelocal(Normal(), testStat, tail=:both)
	pVal > method.alpha ? (rejH0 = false) : (rejH0 = true)
    testStat > 0 ? (bestInput = 2) : (bestInput = 1)
	return DMTest(rejH0, pVal, bestInput, testStat, method)
end
function dm(lossDiff::Vector{<:Number}, method::DMBoot)::DMTest
    length(lossDiff) < 2 && error("Input data vector has length of $(length(lossDiff))")
    method.bootinput.flevel1 != mean && error("flevel1 field in BootInput must be set equal to mean. Please use the keyword constructor for DMBoot as this automatically enforces this behaviour: $(bootinput.flevel1)")
    statVec = dbootlevel1(lossDiff, method.bootinput)
    pVal = pvaluelocal(statVec, 0.0, tail=:both, as=false)
    pVal > method.alpha ? (rejH0 = false) : (rejH0 = true)
    testStat = mean(lossDiff)
    testStat > 0 ? (bestInput = 2) : (bestInput = 1)
	return DMTest(rejH0, pVal, bestInput, testStat, method)
end
#Keyword constructor
function dm(lossDiff::Vector{<:Number}, dmmethod::Symbol ; kwargs...)::DMTest
    dmmethod == :hac && return dm(lossDiff, DMHAC(lossDiff ; kwargs...))
    (dmmethod == :boot || dmmethod == :bootstrap) && return dm(lossDiff, DMBoot(lossDiff ; kwargs...))
    error("Invalid dmmethod: $(dmmethod)")
end
dm(lossDiff::Vector{<:Number})::DMTest = dm(lossDiff, DMBoot(lossDiff))
