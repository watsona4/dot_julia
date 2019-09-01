

operator(pa, ::S)=pa.opS
operator(pa, ::G)=pa.opG

"""
A linear operator corresponding to convolution with either s or g
"""
function create_operator(pa, attrib)
	global to

	fw=(y,x)->@timeit to "F" F!(y, x, pa, attrib)
	bk=(y,x)->@timeit to "Fadj" Fadj!(y, x, pa, attrib)

	return LinearMap{collect(typeof(pa).parameters)...}(fw, bk, 
		  length(pa.optm.cal.d),  # length of output
		  ninv(pa, attrib),
		  ismutating=true, isposdef=true)
end

function F!(y, x, pa, attrib)
	x_to_model!(x, pa, attrib) # modify pa.optm.cal.s 
	Conv.mod!(pa.optm.cal, Conv.D()) # modify pa.optm.cal.d
	copyto!(y,pa.optm.cal.d)
	return nothing
end

function Fadj!(y, x, pa, attrib)
	copyto!(pa.optm.ddcal,x)
	Fadj!(pa, y, x, pa.optm.ddcal, attrib)
	return nothing
end



function filt!(y,x,pa::P_bandpass)
	copyto!(pa.x,x)
	mul!(pa.dfreq, pa.dfftp, pa.x)
	for i in eachindex(pa.dfreq)
		@inbounds pa.dfreq[i] *= pa.filter[i]
	end
	mul!(pa.y, pa.difftp, pa.dfreq)
	copyto!(y,pa.y)
end

function create_operator(pa::P_bandpass)
	fw=(y,x)->filt!(y, x, pa)
	F=LinearMap(fw, fw,# length of output,
                 pa.nt,
                 pa.nt,
                 ismutating=true, isposdef=true)

end
#=

function bandlimit_operator(n)

	function bandlimit!(y, x,)
		responsetype = Bandpass(0.1,0.4; fs=1)
		designmethod = Butterworth(16)
		b=digitalfilter(responsetype, designmethod)
		DSP.filt!(y, b, x)
	end



	function adjtest()
		x=randn(size(F,2))
		y=randn(size(F,1))
		a=LinearAlgebra.dot(y,F*x)
		b=LinearAlgebra.dot(x,adjoint(F)*y)
		c=LinearAlgebra.dot(x, transpose(F)*F*x)
		println("adjoint test: ", a, "\t", b)       
		return isapprox(a,b,rtol=1e-6)
	end

	adjtest()


	=#
