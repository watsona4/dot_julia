module FFTRF

import Interpolations
import Base.Cartesian
import FFTW
import Statistics

"Reduce k"
@generated function reducek(k, dimensionvaltype::Type{Val{N}}) where N
	if N == 2
		setupfinalk = :(finalk = Array{Float64}(undef, div(size(k, 2), 2), div(size(k, 1), 2)))
		innerloop = quote
			finalk[j, i] = real(k[i, j])
		end
	elseif N == 3
		setupfinalk = :(finalk = Array{Float64}(undef, div(size(k, 2), 2), div(size(k, 1), 2), div(size(k, 3), 2)))
		innerloop = quote
			for h = 1:div(size(k, 3), 2)
				finalk[j, i, h] = real(k[i, j, h])
			end
		end
	end
	q = quote
		$setupfinalk
		Ns = Array{Int}(undef, ndims(k))
		sk = size(k)
		for i = 1:ndims(k)
			Ns[i] = div(sk[i], 2)
		end
		for i = 1:div(size(k, 1), 2)
			for j = 1:div(size(k, 2), 2)
				$innerloop
			end
		end
		return finalk
	end
	return q
end

@generated function computesqrtS_f(fouriercoords, Ns, beta, dimensionvaltype)
	if dimensionvaltype == Type{Val{2}}
		loop = quote
			S_f = zeros(Ns[2], Ns[1])
			for j = 1:length(S_f)
				S_f[j] += fouriercoords[1][1 + div(j - 1, length(fouriercoords[2]))] ^ 2
				S_f[j] += fouriercoords[2][1 + rem(j - 1, length(fouriercoords[2]))] ^ 2
			end
		end
	elseif dimensionvaltype == Type{Val{3}}
		loop = quote
			S_f = zeros(Ns[2], Ns[1], Ns[3])
			for j = 1:length(S_f)
				S_f[j] += fouriercoords[1][1 + rem(div(j - 1, length(fouriercoords[2])), length(fouriercoords[1]))] ^ 2
				S_f[j] += fouriercoords[2][1 + rem(j - 1, length(fouriercoords[2]))] ^ 2
				S_f[j] += fouriercoords[3][1 + div(j - 1, length(fouriercoords[1]) * length(fouriercoords[2]))] ^ 2
			end
		end
	else
		error("unsupported dimension: $dimensionvaltype")
	end
	q = quote
		$loop
		for i = 1:length(S_f)
			S_f[i] = S_f[i] ^ (.25 * beta)
			if isinf(S_f[i])
				S_f[i] = 0
			end
		end
		return S_f
	end
	return q
end

function mulbyphi(S::Array)
	phi = randn(size(S))
	result = Array{Complex{eltype(S)}}(undef, size(S))
	for i = 1:length(phi)
		result[i] = S[i] * Complex{eltype(S)}(cospi(2 * phi[i]), sinpi(2 * phi[i]))
	end
	return result
end

function powerlaw_structuredgrid(Ns::Vector, k0::Number, dk::Number, beta::Number)
	originalNs = Ns
	Ns = 2 * Ns
	fouriercoords = Array{Array{Float64, 1}}(undef, length(Ns))
	for i = 1:length(Ns)
		fouriercoords[i] = vcat(collect(0:originalNs[i]), -1 * collect((originalNs[i] - 1):-1:1))
	end
	sqrtS_f = computesqrtS_f(fouriercoords, Ns, beta, Val{length(Ns)})
	result = mulbyphi(sqrtS_f)
	kcomplex = FFTW.ifft(result)
	finalk = reducek(kcomplex, Val{length(Ns)}) # the result is periodic and 2x (in each dimension) as big as it needs to be -- make it smaller and non-periodic
	stdfinalk = Statistics.std(finalk)
	meanfinalk = Statistics.mean(finalk)
	for i = 1:length(finalk)
		finalk[i] = dk * (finalk[i] - meanfinalk) / stdfinalk + k0
	end
	return finalk
end

function powerlaw_unstructuredgrid(points::Matrix, Ns::Vector, k0::Number, dk::Number, beta::Number)
	structuredvals = powerlaw_structuredgrid(Ns, k0, dk, beta)
	return interpolate(points, structuredvals, Val{length(Ns)})
end

@generated function interpolate(points::Matrix, structuredvals, dimensionvaltype)
	if dimensionvaltype == Type{Val{2}}
		ndims = 2
	elseif dimensionvaltype == Type{Val{3}}
		ndims = 3
	else
		error("unsupported dimension: $dimensionvaltype")
	end
	t = :(@Base.Cartesian.ntuple $ndims x)
	q = quote
		@Base.Cartesian.nexprs $ndims j->begin minx_j, maxx_j = extrema(points[j, :]) end
		@Base.Cartesian.nexprs $ndims j->begin x_j = range(minx_j; step=(maxx_j - minx_j) / (size(structuredvals, j) - 1), length=size(structuredvals, j)) end
		# valinterp = Grid.CoordInterpGrid($t, structuredvals, Grid.BCnil, Grid.InterpLinear)
		valinterp = Interpolations.scale(Interpolations.interpolate(structuredvals, Interpolations.BSpline(Interpolations.Linear())), $t...)
		valexterp = Interpolations.extrapolate(valinterp, Interpolations.Flat())
		result = Array{Float64}(undef, size(points, 2))
		for i = 1:length(result)
			result[i] = valexterp(points[:, i]...)
		end
		return result
	end
	return q
end

end
