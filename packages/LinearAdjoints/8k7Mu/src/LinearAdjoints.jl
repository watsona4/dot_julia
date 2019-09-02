module LinearAdjoints

import Test
import GeostatInversion
FDDerivatives = GeostatInversion.FDDerivatives
import LinearAlgebra
import MetaProgTools
import SparseArrays

const specialsymbolI = :___la___I
const specialsymbolJ = :___la___J
const specialsymbolV = :___la___V

include("transforms.jl")
include("calculus.jl")
include("sparsematrix.jl")
include("vector.jl")

function writegetlinearindex(vars::Vector)
	gli = quote end
	for i = 1:length(vars)
		priorlengthexpression = :(0)
		for j = 1:i - 1
			priorlengthexpression = :($priorlengthexpression + length($(vars[j])))
		end
		indexvar1 = gensym()
		indexvar2 = gensym()
		q = quote
			function getlinearindex(::Type{$(Val{vars[i]})})
				return $priorlengthexpression + 1
			end
			function getlinearindex(::Type{$(Val{vars[i]})}, indices...)
				linearindex = $priorlengthexpression + 1
				for $indexvar1 = 1:length(indices)
					offset = 1
					for $indexvar2 = 1:$indexvar1 - 1
						offset *= size($(vars[i]), $indexvar2)
					end
					linearindex += (indices[$indexvar1] - 1) * offset
				end
				return linearindex
			end
		end
		push!(gli.args, q)
	end
	return gli
end

function setupbackslash(A)
	Af = LinearAlgebra.factorize(A)
	function solve(b, transpose=false)
		if transpose
			return vec(Af' \ b)
		else
			return Af \ b
		end
	end
end

macro solve(name, assemble_A_func_symbol, assemble_b_func_symbol, setupsolver=:(LinearAdjoints.setupbackslash))
	q = quote
		function $name(args...)
			A = $assemble_A_func_symbol(args...)
			b = $assemble_b_func_symbol(args...)
			solver = $setupsolver(A)
			x = solver(b)
			#=
			Af = LinearAlgebra.factorize(A)
			x = Af \ b
			=#
			return x
		end
	end
	return :($(esc(q)))
end

macro adjoint(name, assemble_A_func_symbol, assemble_b_func_symbol, objfunc_symbol, objfunc_x_symbol, objfunc_p_symbol, setupsolver=:(LinearAdjoints.setupbackslash))
	if isa(objfunc_symbol, Symbol)#they want a gradient
		q = quote
			function $name(args...)
				A = $assemble_A_func_symbol(args...)
				b = $assemble_b_func_symbol(args...)
				solver = $setupsolver(A)
				x = solver(b)
				g_x = $objfunc_x_symbol(x, args...)
				lambda = solver(g_x, true)
				A_px = $(Meta.parse(string(assemble_A_func_symbol, "_px")))(x, args...)
				b_p = $(Meta.parse(string(assemble_b_func_symbol, "_p")))(args...)
				gradient = (b_p - A_px) * lambda + $objfunc_p_symbol(x, args...)
				of = $objfunc_symbol(x, args...)
				return x, of, gradient
			end
		end
	elseif objfunc_symbol.head == :tuple#they want a jacobian
		q = quote
			function $name(args...)
				A = $assemble_A_func_symbol(args...)
				b = $assemble_b_func_symbol(args...)
				solver = $setupsolver(A)
				x = solver(b)
				gradients = Array{Array{Float64, 1}}(undef, $(length(objfunc_symbol.args)))
				ofs = Array{Float64}(undef, $(length(objfunc_symbol.args)))
				objfuncs = [$(objfunc_symbol.args...)]
				objfunc_xs = [$(objfunc_x_symbol.args...)]
				objfunc_ps = [$(objfunc_p_symbol.args...)]
				for i = 1:$(length(objfunc_symbol.args))
					g_x = objfunc_xs[i](x, args...)
					lambda = solver(g_x, true)
					A_px = $(Meta.parse(string(assemble_A_func_symbol, "_px")))(x, args...)
					b_p = $(Meta.parse(string(assemble_b_func_symbol, "_p")))(args...)
					gradient = (b_p - A_px) * lambda + objfunc_ps[i](x, args...)
					gradients[i] = gradient
					of = objfuncs[i](x, args...)
					ofs[i] = of
				end
				return x, ofs, gradients
			end
		end
	end
	return :($(esc(q)))
end

function vectorargs2args(x, diffargs, args...)
	thisargs = Array{Any}(undef, length(args))
	for i = 1:length(args)
		thisargs[i] = deepcopy(args[i])
	end
	i = 1
	for j = 1:length(diffargs)
		if diffargs[j]
			temp = x[i:i + length(args[j]) - 1]
			if isa(thisargs[j], Number)
				thisargs[j] = temp[1]
			else
				thisargs[j] = reshape(temp, size(args[j]))
			end
			i += length(args[j])
		end
	end
	return thisargs
end

function args2vectorargs(diffargs, args...)
	numparams = 0
	for i = 1:length(diffargs)
		if diffargs[i]
			numparams += length(args[i])
		end
	end
	x = Array{Float64}(undef, numparams)
	j = 1
	for i = 1:length(args)
		if diffargs[i]
			x[j:j + length(args[i]) - 1] .= args[i]
			j += length(args[i])
		end
	end
	return x
end

function testassembleb_p(assembleb, assembleb_p, diffargs::Array{Bool, 1}, args...; tol=100*sqrt(eps(Float64)))
	@assert length(diffargs) == length(args)
	b_p = assembleb_p(args...)
	#assembleb_pvectorargs(x) = vec(full(assembleb(vectorargs2args(x, diffargs, args...)...)))
	assembleb_pvectorargs(x) = assembleb(vectorargs2args(x, diffargs, args...)...)
	J = FDDerivatives.makejacobian(assembleb_pvectorargs)
	fdassembleb_p(x) = J(x)'
	fdb_p = fdassembleb_p(args2vectorargs(diffargs, args...))
	@Test.test size(fdb_p) == size(b_p)
	for i = 1:size(fdb_p, 1)
		for j = 1:size(fdb_p, 2)
			@Test.test fdb_p[i, j] ≈ b_p[i, j] atol=tol
		end
	end
end

function testadjoint(adjointfunc, diffargs::Array{Bool, 1}, args...; tol=100*sqrt(eps(Float64)))
	@assert length(diffargs) == length(args)
	u, of, gradient = adjointfunc(args...)
	function ofwithvectorargs(x)
		thisargs = vectorargs2args(x, diffargs, args...)
		u, of, gradient = adjointfunc(thisargs...)
		return of
	end
	fdgradient = FDDerivatives.makegradient(ofwithvectorargs)
	x = args2vectorargs(diffargs, args...)
	fdgrad = fdgradient(x)
	@Test.test length(gradient) == length(fdgrad)
	@Test.test length(gradient) == length(x)
	for i = 1:length(x)
		@Test.test fdgrad[i] ≈ gradient[i] atol=tol
	end
end

end
