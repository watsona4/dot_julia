module Linv

function getstehfestcoefficients(N::Int64=18)
	V = Array{Float64}(undef, N)
	for i = 1:N
		V[i] = 0.
		for k = floor(Int, (i + 1) / 2):min(i, fld(N, 2))
			V[i] += k ^ (fld(N, 2) + 0) * factorial(2.0 * k) / (factorial(fld(N, 2) - k) * factorial(k) * factorial(k - 1.0) * factorial(i - k) * factorial(2.0 * k - i))
		end
		V[i] *= (-1) ^ (fld(N, 2) + i)
	end
	return V
end

function linv(F::Function, V::Array{Float64, 1}, t::Number)
	s = log(2.) / t
	ft = 0
	for i = 1:size(V)[1]
		ft += V[i] * F(s * i)
	end
	ft *= s
	return ft
end

function makelaplaceinverse(F::Function, N::Int64=18)
	if N < 0 || N % 2 != 0
		error("N must be positive and divisible by 2")
	end
	V = getstehfestcoefficients(N)
	return t->linv(F, V, t)
end

end
