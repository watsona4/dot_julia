"Random Matrix Factorization Functions"
module RandMatFact

import Random
using LinearAlgebra

function colnorms(Y)
	norms = Array{Float64}(undef, size(Y, 2))
	for i = 1:size(Y, 2)
		norms[i] = norm(Y[:, i])
	end
	return norms
end

function rangefinder(A; epsilon=1e-8, r=10)#implements algorithm 4.2 in halko et al
	m = size(A, 1)
	n = size(A, 2)
	Yfull = zeros(Float64, n, r + min(n, m))
	Y = view(Yfull, :, 1:r)
	BLAS.gemm!('N', 'N', 1., A, randn(n, r), 0., Y)
	omega = Array{Float64}(undef, n)
	j = 0
	Qfull = zeros(Float64, m, min(n, m))
	tempvec = Array{Float64}(undef, m)
	Aomega = Array{Float64}(undef, m)
	while maximum(colnorms(view(Yfull, :, j+1:j+r))) > epsilon / sqrt(200 / pi)
		j = j + 1
		Yj = view(Yfull, :, j)
		Q = view(Qfull, :, 1:j - 1)
		QtYj = BLAS.gemv('T', 1., Q, Yj)
		Yj -= Q * QtYj
		q = Yj / norm(Yj)
		Qj = view(Qfull, :, j)
		BLAS.axpy!(1 / norm(Yj), Yj, Qj)
		Q = view(Qfull, :, 1:j)
		Random.randn!(omega)
		Aomega = BLAS.gemv!('N', 1., A, omega, 0., Aomega)
		QtAomega = BLAS.gemv('T', 1., Q, Aomega)
		ynew = Aomega - Q * QtAomega
		Yfull[:, r + j] = ynew
		Qj = view(Qfull, :, j)
		for i = j + 1:j + r - 1
			Yi = view(Yfull, :, i)
			BLAS.axpy!(-dot(Qj, Yi), Qj, Yi)
		end
	end
	return Qfull[:, 1:j]
end

function rangefinder(A, l::Int64, numiterations::Int64)
	#TODO rewrite this to use qrfact! and lufact! to save on memory (we are always overwriting Q anyway)
	m = size(A, 1)
	n = size(A, 2)
	Omega = randn(n, l) #Gaussian requires less oversampling but is more costly to construct, see sect 4.6 Halko
	Y = A * Omega
	if numiterations == 0
		F = LinearAlgebra.qr(Y, Val(true))#pivoted QR is more numerically stable
		return Matrix(F.Q)
	elseif numiterations > 0
		F = LinearAlgebra.lu(Y)
		Q = F.L
	else
		error("parameter numiterations should be positive, but numiterations=$numiterations")
	end
	#Conduct normalized power iterations.
	for i = 1:numiterations
		Q = A' * Q
		F = LinearAlgebra.lu(Q)
		Q = F.L
		Q = A * Q
		if i < numiterations
			F = LinearAlgebra.lu(Q)
			Q = F.L
		else
			F = LinearAlgebra.qr(Q, Val(true))
			Q = Matrix(F.Q)
		end
	end
	return Q
end

"Random SVD based on algorithm 5.1 from Halko et al."
function randsvd(A, K::Int, p::Int, q::Int)
	Q = rangefinder(A, K + p, q);
	B = Q' * A;
	(), S, V = svd(B);#This is algorithm 5.1 from Halko et al, Direct SVD
	Sh = LinearAlgebra.Diagonal(sqrt.([S[1:K]; zeros(p)]))#Cut back to K from K+p
	Z = V * Sh
	return Z
end

function eig_nystrom(A, Q)#implements algorithm 5.5 from Halko et al
	B1 = A * Q
	B2 = Q' * B1
	C = LinearAlgebra.cholesky(Hermitian(B2)).U
	F = B1 * inv(C)#this should be replaced by triangular solve if it is slowing things down
	U, Sigmavec, V = svd(F)
	#Sigma = diagm(Sigmavec)
	#Lambda = Sigma * Sigma
	#return U, Lambda
	return U, Sigmavec
end

end
