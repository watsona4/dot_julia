function mcs(l::Matrix{T}, method::MCSBootLowRAM)::MCSTest where {T<:Number}
	(N, K) = size(l)
	N < 2 && error("Input must have at least two observations")
	K < 2 && error("Input must have at least two models")
	T != Float64 && (l = Float64[ Float64(l[j, k]) for j = 1:size(l, 1), k = 1:size(l, 2) ]) #Convert input to Float64
	numResample = method.bootinput.numresample
	#Get bootstrap indices
	inds = dbootinds(Float64[], method.bootinput)
	#Get matrix of loss differential sample means
	lMuVec = vec(mean(l, dims=1))
	iM = ltri_cart_index(collect(1:K)) #Build a matrix of lower triangular cartesian indices
	S = size(iM, 1) #Total number of cross series
	lDMuCross = Float64[ lMuVec[iM[s, 2]] - lMuVec[iM[s, 1]] for s = 1:S ] #diag = 0.0, utri = -1.0*ltri
	#Get array of  bootstrapped loss differential sample means
	lDMuCrossStar = Array{Float64}(undef, S, numResample)
	for m = 1:numResample
		lMuVecStar = mean(l[inds[m], :], dims=1)
		lDMuCrossStar[:, m] = Float64[ lMuVecStar[iM[s, 2]] - lMuVecStar[iM[s, 1]] for s = 1:S ] #diag = 0.0, utri = -1.0*ltri
	end
	#Get variance estimates from bootstrapped loss differential sample means (note, we centre on lDMu since these are the population means for the resampled data)
	lDMuCrossVar = Float64[ varm(lDMuCrossStar[s, :], lDMuCross[s], corrected=false) for s = 1:S ] #diag = 1.0, utri = ltri
	#Get original and re-sampled t-statistics
	tStatCrossStar = Float64[ (lDMuCrossStar[s, m] - lDMuCross[s]) / sqrt(lDMuCrossVar[s]) for s = 1:S, m = 1:numResample ] #diag = 0.0, utri = -1.0*ltri
	tStatCross = Float64[ lDMuCross[s] / sqrt(lDMuCrossVar[s]) for s = 1:S ] #diag = 0.0, utri = -1.0*ltri
	#Perform model confidence set method A
	inA = collect(1:K) #Models in MCS (start off with all models in MCS)
	outA = Array{Int}(undef, K) #Models not in MCS (start off with no models in MCS)
	pValA = ones(Float64, K) #p-values constructed in loop
	for k = 1:K-1
		iIn = ltri_index_match(K, inA) #Linear indices of models that are still in the MCS
		bootSumIn = vec(sum(abs2, tStatCrossStar[iIn, :], dims=1))
		origSumIn = sum(abs2, tStatCross[iIn])
		pValA[k] = mean(bootSumIn .> origSumIn)
		lDAvgMuCross = vec(mean(msym_mat_from_ltri_inds(lDMuCross, iIn), dims=1))
		lDAvgMuCrossStar = Array{Float64}(undef, numResample, trinumroot(length(iIn))+1)
		for s = 1:numResample
			lDAvgMuCrossStar[s, :] = mean(msym_mat_from_ltri_inds(lDMuCrossStar[:, s], iIn), dims=1)
		end
		lDAvgMuCrossVar = Float64[ varm(lDAvgMuCrossStar[:, k], lDAvgMuCross[k], corrected=false) for k = 1:length(lDAvgMuCross) ]
		tStatCrossInc = lDAvgMuCross ./ sqrt.(lDAvgMuCrossVar)
		iRemove = argmax(tStatCrossInc) #Find index in inA of model to be removed
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
		iIn = ltri_index_match(K, inB) #Linear indices of models that are still in the MCS
		bootMaxIn = Float64[ maximum(abs, tStatCrossStar[iIn, m]) for m = 1:numResample ]
		origMaxIn = maximum(abs, tStatCross[iIn])
		pValB[k] = mean(bootMaxIn .> origMaxIn)
		lDAvgMuCross = vec(mean(msym_mat_from_ltri_inds(lDMuCross, iIn), dims=1))
		lDAvgMuCrossStar = Array{Float64}(undef, numResample, trinumroot(length(iIn))+1)
		for s = 1:numResample
			lDAvgMuCrossStar[s, :] = mean(msym_mat_from_ltri_inds(lDMuCrossStar[:, s], iIn), dims=1)
		end
		lDAvgMuCrossVar = Float64[ varm(lDAvgMuCrossStar[:, k], lDAvgMuCross[k], corrected=false) for k = 1:length(lDAvgMuCross) ]
		tStatCrossInc = lDAvgMuCross ./ sqrt.(lDAvgMuCrossVar)
		iRemove = argmax(tStatCrossInc) #Find index in inB of model to be removed
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
#Local function for triangular numbers
trinum(K::Int) = Int((K*(K+1))/2)
trinumroot(triNum::Int) = Int((sqrt(8*triNum + 1) - 1) / 2)
#Local functions for matching lower triangular cartesian indices to a linear index
ltri_index_match(K::Int, i::Int, j::Int) = trinum(K-1) - trinum(K-j-1) - K + i
function ltri_index_match(K::Int, cartInds::Matrix{Int})
	size(cartInds, 2) != 2 && error("Invalid cartesian index matrix")
	tnK = trinum(K-1)
	return(Int[ tnK - trinum(K - cartInds[s, 2] - 1) - K + cartInds[s, 1] for s = 1:size(cartInds, 1) ])
end
ltri_index_match(K::Int, inds::Vector{Int}) = ltri_index_match(K, ltri_cart_index(inds))
#Local function for constructing a matrix of lower triangular cartesian indices
function ltri_cart_index(inds::Vector{Int})
	indsOut = Array{Int}(undef, trinum(length(inds)-1), 2)
	c = 1
	for k = 1:length(inds)-1
		for j = k+1:length(inds)
			indsOut[c, 1] = inds[j]
			indsOut[c, 2] = inds[k]
			c += 1
		end
	end
	return(indsOut)
end
#Local function for constructing a matrix from a lower triangle using linear indices (no diagonal), and minus one times the lower triangle (no diagonal). Two components are stuck together transposed to each other.
function msym_mat_from_ltri_inds(x::AbstractVector{T}, linInds::Vector{Int}) where {T<:Number}
	K = trinumroot(length(linInds))
	xOut = Array{T}(undef, K, K+1)
	iSt = 1
	for k = K:-1:1
		triCol = x[linInds[iSt:iSt+k-1]]
		xOut[K-k+1:end, K-k+1] = triCol
		xOut[K-k+1, K-k+2:end] = -1.0 * triCol
		iSt += k
	end
	return(xOut)
end
