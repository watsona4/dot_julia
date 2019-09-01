
"""
	MCSMethod

Abstract type for nesting the various methods that can be used to perform a model confidence set. Subtypes are: \n
	MCSBoot
	MCSBootLowRAM
The subtypes have entries in the help (?) menu.
"""
abstract type MCSMethod end

"""
	MCSBoot(data ; alpha, basecaseindex, kwargs...)

Method type for doing a MCS test using a dependent bootstrap. Relevant keyword arguments are: \n
    alpha=0.05 <- The confidence level to use in the test \n
	basecaseindex=1 <- The MCS does not have a natural basecase. However, the input data is a
		matrix of losses, not loss differentials, and the method itself considers every possible
		loss differential combination. This is far too many to check for determining
		the optimal block length for bootstrapping, so users who wish to auto-estimate
		the appropriate block length can specify a notional base case variable index
		for the purposes of computing a optimal block lengths of all loss differences
		relative to the base case.
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
struct MCSBoot <: MCSMethod
	alpha::Float64
	bootinput::BootInput
	basecaseindex::Int
	function MCSBoot(alpha::Float64, bootinput::BootInput, basecaseindex::Int)
		!(0.0 < alpha < 0.5) && error("alpha = $(alpha). Invalid confidence level.")
		new(alpha, bootinput, basecaseindex)
	end
end
function MCSBoot(data ; alpha::Float64=0.05, basecaseindex::Int=1, kwargs...)::MCSBoot
    return MCSBoot(alpha, BootInput(loss_diff_base_case(data, basecaseindex), kwargs...), basecaseindex)
end

"""
	MCSBootLowRAM(data ; alpha::Float64=0.05, kwargs...)

Method type for doing an MCS test using a dependent bootstrap. This method type has an identical
constructor arguments to MCSBoot, so use ?MCSBoot for more detail.

WARNING: This method corresponds to a MCS algorithm that has double the runtime of MCSBoot, but uses about half as much RAM. The
vast majority of users will want to use MCSBoot.

WARNING: Results from MCSBootLowRAM are not guaranteed to be identical to those from MCSBoot in finite sample, although they
are very likely to both recommend the same set of models in the model confidence set.
"""
struct MCSBootLowRAM <: MCSMethod
	alpha::Float64
	bootinput::BootInput
	basecaseindex::Int
	function MCSBootLowRAM(alpha::Float64, bootinput::BootInput, basecaseindex::Int)
		!(0.0 < alpha < 0.5) && error("alpha = $(alpha). Invalid confidence level.")
		new(alpha, bootinput, basecaseindex)
	end
end
function MCSBootLowRAM(data ; alpha::Float64=0.05, basecaseindex::Int=1, kwargs...)::MCSBootLowRAM
    return MCSBootLowRAM(alpha, BootInput(loss_diff_base_case(data, basecaseindex), kwargs...), basecaseindex)
end

"loss_diff_base_case <- Local function for getting loss differences relative to notional base case for purposes of estimating the block length"
function loss_diff_base_case(l::Matrix{<:Number}, basecaseindex::Int)
	!(1 <= basecaseindex <= size(l, 2)) && error("basecaseindex = $(basecaseindex), which does not lie between 1 and $(size(l,2)) (inclusive)")
	lD = l[:, 1:size(l, 2) .!= basecaseindex] .- l[:, basecaseindex]
	return lD
end


"""
	MCSTest(inQF::Vector{Int}, outQF::Vector{Int}, pvalueQF::Vector{Float64}, inMT::Vector{Int}, outMT::Vector{Int}, pvalueMT::Vector{Float64})

Output type from performing the MCS test proposed in Hansen, Lunde, Nason (2011) "The Model Confidence Set", Econometrica, 79 (2), pp. 453-497. \n
The field names of this type have trailing "QF" or "MT", where QF corresponds to the quadratic form test (see section 3.1.1 of original paper),
while MT corresponds to the maximum t-stat test (see section 3.1.2 of original paper). \n
Note, in the fields of this type, the forecast models input to the MCS method are indicated via an integer counting up from 1 for
each forecast model. These integers correspond to the columns of the input loss matrix; see ?mcs for more info. \n
The fields of this type follow: \n
	inQF <- Models that are in the MCS via the quadratic form method
	outQF <- Models that are not in the MCS via the quadratic form method
	pvalueQF <- The cumulative p-values from the quadratic form method
	inMT <- Models that are in the MCS via the max t-stat method
	outMT <- Models that are not in the MCS via the max t-stat method
	pvalueMT <- The cumulative p-values from the max t-stat method
"""
struct MCSTest #Output from MCS
	inQF::Vector{Int}
	outQF::Vector{Int}
	pvalueQF::Vector{Float64}
	inMT::Vector{Int}
	outMT::Vector{Int}
	pvalueMT::Vector{Float64}
	MCSTest(inQF::Vector{Int}, outQF::Vector{Int}, pvalueQF::Vector{Float64}, inMT::Vector{Int}, outMT::Vector{Int}, pvalueMT::Vector{Float64}) = new(inQF, outQF, pvalueQF, inMT, outMT, pvalueMT)
end
function Base.show(io::IO, a::MCSTest)
	println("Model confidence test results:")
	println("    Quadratic form test models in MCS: $(a.inQF)")
	println("    Maximum t-stat test models in MCS: $(a.inMT)")
end


"""
	mcs(l::Matrix{<:Number}, method ; kwargs...)
	mcs(l::Matrix{<:Number} ; kwargs...)

This function implements the MCS test proposed in Hansen, Lunde, Nason (2011) "The Model Confidence Set", Econometrica, 79 (2), pp. 453-497. \n
Let x_k, k = 1, ..., K, denote K forecasts (from K different forecasting models), and y denote the forecast target.
Let L(., .) denote a loss function.
The first argument of mcs is a matrix where the kth column of the matrix is created by the operation: \n
L(x_k, y) \n
Note that unlike the Reality Check and SPA test, there is no base case for the MCS. \n
The second method argument determines which methodology to use. Currently, only MCSBoot is available and if
this input type is provided, the keyword arguments are not needed.
Alternatively, the user can omit the second argument, and then any keyword arguments will be passed to the
MCSBoot constructor. See ?MCSBoot for more detail. The most relevant keyword arguments are:
    alpha=0.05 <- The confidence level to use in the test \n
	basecaseindex=1 <- The MCS does not have a natural basecase. However, the input data is a
		matrix of losses, not loss differentials, and the method itself considers every possible
		loss differential combination. This is far too many to check for determining
		the optimal block length for bootstrapping, so users who wish to auto-estimate
		the appropriate block length can specify a notional base case variable index
		for the purposes of computing a optimal block lengths of all loss differences
		relative to the base case.
    blocklength=0.0 <- Block length to use with the bootstrap. Default of 0.0 implies
        the block length will be optimally estimated from the data use the method deemed
        most appropriate by the DependentBootstrap package (typically the selection procedure
        of Patton, Politis, and White (2009)). \n
    numresample=1000 <- Number of resamples to use when bootstrapping. \n
    bootmethod=:stationary <- Bootstrap methodology to use, where the default is the
        stationary bootstrap of Politis and Romano (1993) \n
For more detail on the bootstrap options, please see the docs for the DependentBootstrap package. \n
The output of a MCS test is of type MCSTest. Use ?MCSTest for more information. \n
Note, if you are hitting RAM limits, type ?ForecastEval.MCSBootLowRAM at the REPL for more detail on an alternative algorithm that
is also available. \n
Note, for any developers, the main algorithm (associated with MCSBoot) still has the following potential performance issues: \n
	ISSUE 1: Some of the temporary arrays in the loops could probably be eliminated \n
	ISSUE 2: For MCS method A, I think the loop over K could be terminated as soon as cumulative p-values are greater than method.alpha. Need to double check this. \n
	ISSUE 3: Need to add option to do just max(abs) method or just sum(sq) method (or both) \n
Comments or pull requests on these issues would be most welcome on the package github page.
"""
function mcs(l::Matrix{T}, method::MCSBoot)::MCSTest where {T<:Number}
	(N, K) = size(l)
	N < 2 && error("Input must have at least two observations")
	K < 2 && error("Input must have at least two models")
	T != Float64 && (l = Float64[ Float64(l[j, k]) for j = 1:size(l, 1), k = 1:size(l, 2) ]) #Convert input to Float64
	numResample = method.bootinput.numresample
	#Get bootstrap indices
	inds = dbootinds(Float64[], method.bootinput)
	#Get matrix of loss differential sample means
	lMuVec = mean(l, dims=1)
	lDMu = Float64[ lMuVec[k] - lMuVec[j] for j = 1:K, k = 1:K  ]
	#Get array of  bootstrapped loss differential sample means
	lDMuStar = Array{Float64}(undef, K, K, numResample) #This array is affected by ISSUE 1 above
	for m = 1:numResample
		lMuVecStar = mean(l[inds[m], :], dims=1)
		lDMuStar[:, :, m] = Float64[ lMuVecStar[k] - lMuVecStar[j] for j = 1:K, k = 1:K  ]
	end
	#Get variance estimates from bootstrapped loss differential sample means (note, we centre on lDMu since these are the population means for the resampled data)
	#Note, for efficiency, we only use varm to fill out the lower triangular matrix
	lDMuVar = ones(Float64, K, K)
	for j = 2:K
		for k = 1:j-1
			lDMuVar[j, k] = varm(vec(lDMuStar[j, k, :]), lDMu[j, k], corrected=false)
		end
	end
	ltri_to_utri!(lDMuVar)
	#Get original and re-sampled t-statistics
	tStatStar = Float64[ (lDMuStar[j, k, m] - lDMu[j, k]) / sqrt(lDMuVar[j, k]) for j = 1:K, k = 1:K, m = 1:numResample ]
	tStat = Float64[ lDMu[j, k] / sqrt(lDMuVar[j, k]) for j = 1:K, k = 1:K ]
	#Perform model confidence set method A
	inA = collect(1:K) #Models in MCS (start off with all models in MCS)
	outA = Array{Int}(undef, K) #Models not in MCS (start off with no models in MCS)
	pValA = ones(Float64, K) #p-values constructed in loop
	for k = 1:K-1
		bootSum = 0.5 * vec(sum(abs2, tStatStar[inA, inA, :], dims=(1,2)))
		origSum = 0.5 * sum(abs2, tStat[inA, inA])
		pValA[k] = mean(bootSum .> origSum)
		scalingTerm = length(inA) / (length(inA) - 1)
		lDAvgMu = scalingTerm * vec(mean(lDMu[inA, inA], dims=1))
		lDAvgMuStar = scalingTerm * dropdims(mean(lDMuStar[inA, inA, :], dims=1), dims=1)
		lDAvgMuVar = Float64[ varm(vec(lDAvgMuStar[k, :]), lDAvgMu[k], corrected=false) for k = 1:length(lDAvgMu) ]
		tStatInc = lDAvgMu ./ sqrt.(lDAvgMuVar)
		iRemove = argmax(tStatInc) #Find index in inA of model to be removed
		outA[k] = inA[iRemove] #Add model to be removed to excluded list
		deleteat!(inA, iRemove) #Remove model to be removed
	end
	pValA = accumulate(max, pValA)
	outA[end] = inA[1] #Finish constructing excluded models
	iCutOff = findfirst(pValA .>= method.alpha) #method.alpha < 1.0, hence there will always be at least one p-value > method.alpha
	inA = outA[iCutOff:end]
	outA = outA[1:iCutOff-1]
	#Perform model confidence method B
	inB = collect(1:K) #Models in MCS (start off with all models included)
	outB = Array{Int}(undef, K) #Models not in MCS (start off with no models in MCS)
	pValB = ones(Float64, K) #p-values constructed in loop
	for k = 1:K-1
		bootMax = Float64[ maximum(abs, tStatStar[inB, inB, m]) for m = 1:numResample ]
		#bootMax = vec(maximum(abs(tStatStar[inB, inB, :]), [1, 2])) #ALTERNATIVE METHOD
		origMax = maximum(tStat[inB, inB])
		pValB[k] = mean(bootMax .> origMax)
		scalingTerm = length(inB) / (length(inB) - 1)
		lDAvgMu = scalingTerm * vec(mean(lDMu[inB, inB], dims=1))
		lDAvgMuStar = scalingTerm * dropdims(mean(lDMuStar[inB, inB, :], dims=1), dims=1)
		lDAvgMuVar = Float64[ varm(vec(lDAvgMuStar[k, :]), lDAvgMu[k], corrected=false) for k = 1:length(lDAvgMu) ]
		tStatInc = lDAvgMu ./ sqrt.(lDAvgMuVar)
		iRemove = argmax(tStatInc) #Find index in inB of model to be removed
		outB[k] = inB[iRemove] #Add model to be removed to excluded list
		deleteat!(inB, iRemove) #Remove model to be removed
	end
	pValB = accumulate(max, pValB)
	outB[end] = inB[1] #Finish constructing excluded models
	iCutOff = findfirst(pValB .>= method.alpha) #method.alpha < 1.0, hence there will always be at least one p-value > method.alpha
	inB = outB[iCutOff:end]
	outB = outB[1:iCutOff-1]
	#Prepare the output
	mcsOut = MCSTest(inA, outA, pValA, inB, outB, pValB)
end
#Local function to shift lower triangular elements to upper triangular portion of matrix
function ltri_to_utri!(x::AbstractMatrix{T}) where {T<:Number}
	size(x, 1) != size(x, 2) && error("Input matrix  must be symmetric")
	for j = 2:size(x, 1)
		for k = 1:j-1
			x[k, j] = x[j, k]
		end
	end
	return(true)
end
#Keyword wrapper
mcs(l::Matrix{<:Number} ; kwargs...)::MCSTest = mcs(l, MCSBoot(l, kwargs...))
