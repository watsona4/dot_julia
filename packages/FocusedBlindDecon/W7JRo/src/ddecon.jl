

"""
Deterministic Decon, where selet is known
"""
mutable struct ParamD{T<:Real,N}
	np2::Int
	ntd::Int
	nts::Int
	d::Array{T,N}
	g::Array{T,N}
	s::Vector{T}
	dpad::Array{T,N}
	gpad::Array{T,N}
	spad::Vector{T}
	dfreq::Array{Complex{T},N}
	greq::Array{Complex{T},N}
	sfreq::Array{Complex{T},1}
	fftplan::FFTW.rFFTWPlan
	ifftplan::FFTW.Plan
	fftplans::FFTW.rFFTWPlan
	ϵ::T
end

function ParamD(;ntd=1, nts=1, dims=(), np2=nextfastfft(maximum([2*nts, 2*ntd])), # fft dimension for plan
			d=zeros(ntd, dims...), s=zeros(nts), g=zeros(d), ϵ=1e-2)
	T=eltype(d)

	dims=size(d)[2:end]
	nrfft=div(np2,2)+1
	fftplan=plan_rfft(zeros(T, np2,dims...),[1])
	ifftplan=plan_irfft(complex.(zeros(T, nrfft,dims...)),np2,[1])
	fftplans=plan_rfft(zeros(T, np2,),[1])
	
	dfreq=complex.(zeros(T,nrfft,dims...))
	greq=complex.(zeros(T,nrfft,dims...))
	sfreq=complex.(zeros(T,nrfft))

	# preallocate padded arrays
	dpad=(zeros(T,np2,dims...))
	gpad=(zeros(T,np2,dims...))
	spad=(zeros(T,np2,))

	sv=normalize(s) # make a copy, don't edit s

	return ParamD(np2,ntd,nts,d,g,sv,dpad,gpad,spad,dfreq,greq,sfreq,
		fftplan, ifftplan, fftplans, ϵ)

end

"""
Convolution that allocates `Param` internally.
"""
function mod!(
	   d::AbstractArray{T,N}, 
	   s::AbstractVector{T}, attrib::Symbol) where {T,N}
	ntd=size(d,1)
	ntg=size(g,1)
	nts=size(s,1)

	# allocation of freq matrices
	pa=ParamD(ntd=ntd, nts=nts, s=s, d=d)

	# using pa, return d, g, s according to attrib
	mod!(pa)
end

"""
Convolution modelling with no allocations at all.
By default, the fields `g`, `d` and `s` in pa are modified accordingly.
Otherwise use keyword arguments to input them.
"""
function mod!(pa::ParamD; 
	      g=pa.g, d=pa.d, s=pa.s # external arrays to be modified
	     )
	T=eltype(pa.d)
	ntd=size(pa.d,1)
	nts=size(pa.s,1)
	
	# initialize freq vectors
	pa.dfreq[:] = complex(T(0))
	pa.greq[:] = complex(T(0))
	pa.sfreq[:] = complex(T(0))

	pa.gpad[:]=T(0)
	pa.dpad[:]=T(0)
	pa.spad[:]=T(0)

	# necessary zero padding
	Conv.pad_truncate!(g, pa.gpad, ntd-1, 0, pa.np2, 1)
	Conv.pad_truncate!(d, pa.dpad, ntd-1, 0, pa.np2, 1)
	Conv.pad_truncate!(s, pa.spad, nts-1, 0, pa.np2, 1)

	A_mul_B!(pa.sfreq, pa.fftplans, pa.spad)
	A_mul_B!(pa.dfreq, pa.fftplan, pa.dpad)
	for i in eachindex(pa.greq)
		ii=ind2sub(pa.greq,i)[1]
		pa.greq[i]=pa.dfreq[i]*inv(pa.sfreq[ii]*conj(pa.sfreq[ii])+pa.ϵ)
	end
	A_mul_B!(pa.gpad, pa.ifftplan, pa.greq)

	Conv.pad_truncate!(g, pa.gpad, ntd-1, 0, pa.np2, -1)
	

	return g

end


