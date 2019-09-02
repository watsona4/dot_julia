"""
    gammaHSIC(X::Array{T, 2}, Y::Array{T, 2})

"""
function gammaHSIC(X::Array{T, 2}, Y::Array{T, 2}; α = 0.1, randomSubSet = 100, kernelSize = -1) where T <: Real

	M = size(X)[1]

	# get kernel sizes
	if kernelSize == -1
		sigx = estimateKernelSize(X, sampleSize = randomSubSet)
		sigy = estimateKernelSize(Y, sampleSize = randomSubSet)
	else
		sigx = kernelSize
		sigy = kernelSize
	end

	bone = ones(T, M, 1)
	H = eye(M) - 1/M * ones(T, M,M)

	K = rbfDotProduct(X, X, sigx)
	L = rbfDotProduct(Y, Y, sigy)

	# NOTE: these are slightly biased estimates of centred Gram matrices
	Kc = H*K*H
	Lc = H*L*H

	# NOTE: we fit Gamma to testStat*M
	testStat = 1/M * sum(sum(Kc'.*Lc))

	varHSIC = (1/6 * Kc.*Lc).^2
	varHSIC = 1/M/(M-1)* (  sum(sum(varHSIC)) - sum(diag(varHSIC))  ) # second subtracted term is bias correction
	varHSIC = 72*(M-4)*(M-5)/M/(M-1)/(M-2)/(M-3) * varHSIC

	K = K-diagm(0 => diag(K))
	L = L-diagm(0 => diag(L))

	muX = 1/M/(M-1)*bone'*(K*bone)
	muY = 1/M/(M-1)*bone'*(L*bone)

	mHSIC  = 1/M * ( 1 .+muX*muY - muX - muY )

	al = mHSIC^2 / varHSIC
	bet = varHSIC*M ./ mHSIC

	return (testStat, gammainvcdf(al[1], bet[1], 1 - α))

end
