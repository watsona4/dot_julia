

mutable struct BD{T}
	om::ObsModel{T}
	optm::OptimModel{T}
	gx::X{T}
	sx::X{T}
	sxp::Sxparam
	snorm_flag::Bool 	# restrict s along a unit circle during optimization
	snormmat::Matrix{T}            # stored outer product of s
	dsnorm::Vector{T}		# gradient w.r.t. normalized selet
	attrib_inv::Symbol
	verbose::Bool
	err::DataFrames.DataFrame
	opG::LinearMaps.LinearMap{T}
	opS::LinearMaps.LinearMap{T}
	pbandpass::P_bandpass{T}
end



"""
Constructor for the blind deconvolution problem
"""
function BD(ntg, nt, nr, nts; 
	    gprecon_attrib=:none,
	       sxp=Sxparam(1,:all),
	       gweights=nothing,
	       goptim=nothing,
	       gαvec=nothing,
	       soptim=nothing,
	       sαvec=nothing,
	       sprecon=nothing,
	       snorm_flag=false,
	       fft_threads=false,
	       fftwflag=FFTW.PATIENT,
	       dobs=nothing, gobs=nothing, sobs=nothing, verbose=false, attrib_inv=:g,
	       ) 
	# determine type of IBD
	if(!(dobs===nothing))
		T=eltype(dobs)
	else
		T1=eltype(sobs)
		T2=eltype(gobs)
		(T1≠T2) ? error("type difference") : (T=T1)
	end


	if(ntg+nts-1 ≠ nt)
		error("invalid sizes for convolutional model")
	end

	# use maximum threads for fft
	fft_threads &&  (FFTW.set_num_threads(Sys.CPU_THREADS))

	# store observed data
	om=ObsModel(ntg, nt, nr, nts, T, d=dobs, g=gobs, s=sobs)

	# create models depending on mode
	optm=OptimModel(ntg, nt, nr, nts, T, fftwflag=fftwflag, 
	slags=[nts-1, 0], 
	dlags=[nt-1, 0], 
	glags=[ntg-1, 0], 
		 )

	# inversion variables allocation
	gx=X(length(optm.cal.g), T)
	sx=X(length(optm.cal.s), T)

	snorm_flag ?	(snormmat=zeros(T,nts, nts)) : (snormmat=zeros(T,1,1))
	snorm_flag ?	(dsnorm=zeros(T,nts)) : (dsnorm=zeros(T,1))

	err=DataFrame(g=[], g_nodecon=[], s=[], d=[], front_load=[], whiteness=[])

	# dummy
	opG=LinearMap{T}(x->0.0, y->0.0,1,1, ismutating=true)
	opS=LinearMap{T}(x->0.0, y->0.0,1,1, ismutating=true)

	pbandpass=DC.P_bandpass(T, fmin=0.2, fmax=0.4, nt=optm.nt)

	pa=BD(
		om,		optm,			gx,		sx,	sxp, snorm_flag,
		snormmat,		dsnorm,		attrib_inv,		verbose,
		err, opG, opS,pbandpass)		# trying to penalize the energy in the correlations of g (not in practice),


	# update operators
	pa.opG=create_operator(pa, G())
	pa.opS=create_operator(pa, S())


	gobs=pa.om.g
	sobs=pa.om.s
	dobs=pa.om.d

	# obs.g <-- gobs
	replace!(pa.optm, gobs, :obs, :g )
	# obs.s <-- sobs
	replace!(pa.optm, sobs, :obs, :s )
	# obs.d <-- dobs
	copyto!(pa.optm.obs.d, dobs) #  


	add_precons!(pa, pa.om.g, attrib=gprecon_attrib)

	initialize!(pa)
	#update_func_grad!(pa,goptim=goptim,soptim=soptim,gαvec=gαvec,sαvec=sαvec)

	return pa
	
end



function update_prepare!(pa::BD, ::S)
end
function update_prepare!(pa::BD, ::G)
end
function update_finalize!(pa::BD, ::S)

	if(STF_FLAG)
		for i in eachindex(pa.optm.cal.s)
			if(pa.optm.cal.s[i] <0.0)
				pa.optm.cal.s[i]=0.0
			end
		end
	end
end
function update_finalize!(pa::BD, ::G)
end

function model_to_x!(x, pa::BD, ::S)
	for i in eachindex(x)
		x[i]=^(pa.optm.cal.s[i],inv(pa.sxp.n))*pa.sx.precon[i]
	end
	return nothing
end
function model_to_x!(x, pa::BD, ::G)
	for i in eachindex(x)
		x[i]=pa.optm.cal.g[i]*pa.gx.precon[i] 		# multiply by gprecon
	end
	return nothing
end



function x_to_model!(x, pa::BD, ::S)
	for i in eachindex(pa.optm.cal.s)
		# put same in all receivers
		pa.optm.cal.s[i]=^(x[i],pa.sxp.n)*pa.sx.preconI[i]
	end
	if(pa.snorm_flag)
		xn=vecnorm(x)
		scale!(pa.optm.cal.s, inv(xn))
	end
	return nothing
end
function x_to_model!(x, pa::BD, ::G)
	for i in eachindex(pa.optm.cal.g)
		pa.optm.cal.g[i]=x[i]*pa.gx.preconI[i]
	end
	return pa
end



"""
Create preconditioners using the observed Green Functions.
* `cflag` : impose causaulity by creating gprecon using gobs
* `max_tfrac_gprecon` : maximum length of precon windows on g
"""
function add_precons!(pa::BD, gobs; αexp=0.0, cflag=true,
		       max_tfrac_gprecon=1.0, attrib=:focus)
	
	ntg=pa.om.ntg
	nts=pa.om.nts

	ntgprecon=round(Int,max_tfrac_gprecon*ntg);

	nr=size(gobs,2)
	sprecon=ones(nts)
	gprecon=ones(ntg, nr); 
	gweights=ones(ntg, nr); 
	if(attrib==:windows)
		for ir in 1:nr
			g=normalize(view(gobs,:,ir))
			indz=findfirst(x->abs(x)>1e-6, g)
		#	if(indz > 1) 
		#		indz -= 1 # window one sample less than actual
		#	end
			if(!cflag && indz≠0)
				indz=1
			end
			if(indz≠0)
				for i in 1:indz-1
					gprecon[i,ir]=0.0
					gweights[i,ir]=0.0
				end
				for i in indz:indz+ntgprecon
					if(i≤ntg)
						gweights[i,ir]=exp(αexp*(i-indz-1)/ntg)  # exponential weights
						gprecon[i,ir]=exp(αexp*(i-indz-1)/ntg)  # exponential weights
					end
				end
				for i in indz+ntgprecon+1:ntg
					gprecon[i,ir]=0.0
					gweights[i,ir]=0.0
				end
			else
				gprecon[:,ir]=0.0
				gweights[:,ir]=0.0
			end
		end
	elseif(attrib==:focus)
		ir0=inear(gobs)
		# first receiver is a spike
		gprecon[2:end,ir0]=0.0

	end

	add_gprecon!(pa, gprecon)
	add_gweights!(pa, gweights)
	add_sprecon!(pa, sprecon)
 
	return pa
end


"return index of closest receiver"
function inear(gobs, threshold=1e-6)
	nr=size(gobs,2)
	ir0=argmin([findfirst(x->abs(x)>threshold, vec(gobs[:,ir])) for ir in 1:nr])
	return ir0
end


function bd!(pa::BD, io=stdout; tol=1e-6)

	if(io===nothing)
		logfilename=joinpath(pwd(),string("XBD",Dates.now(),".log"))
		io=open(logfilename, "a+")
	end

	update_all!(pa, io, max_reroundtrips=1, max_roundtrips=100000, roundtrip_tol=tol)

	err!(pa)
end

function F!(pa::BD,x::AbstractVector, attrib::S)
	compute=(x!=pa.sx.last_x)
	if(compute)
		x_to_model!(x, pa, attrib) #
		copyto!(pa.sx.last_x, x)
		Conv.mod!(pa.optm.cal, Conv.D()) # modify pa.optm.cal.d
		return pa
	end
end

function F!(pa::BD,x::AbstractVector, ::G)
	compute=(x!=pa.gx.last_x)
	if(compute)
		x_to_model!(x, pa, G())
		copyto!(pa.gx.last_x, x)
		Conv.mod!(pa.optm.cal, Conv.D()) # modify pa.optm.cal.d
		return pa
	end
end


"""
Apply Fadj to dcal 
"""
function Fadj!(pa::BD, storage, x, dcal, ::S)
	fill!(storage, 0.0)
	Conv.mod!(pa.optm.cal, Conv.S(), d=dcal, s=pa.optm.ds)
	for j in 1:size(pa.optm.ds,1)
		storage[j] = pa.optm.ds[j]
	end

	# apply precon
	for i in eachindex(storage)
		if(iszero(pa.sx.precon[i]))
			storage[i]=0.0
		else
			storage[i] = storage[i]*pa.sxp.n*^(x[i],pa.sxp.n-1)*pa.sx.preconI[i]
		end
	end
	# factor, because s was divided by norm of x
	if(pa.snorm_flag)
		copyto!(pa.optm.dsnorm, storage)
		Misfits.derivative_vector_magnitude!(storage,pa.optm.dsnorm,x,pa.snormmat)
	end
	return storage
end

function Fadj!(pa::BD, storage, x, dcal, ::G)
	Conv.mod!(pa.optm.cal, Conv.G(), g=pa.optm.dg, d=dcal)

	for i in eachindex(storage)
		if(iszero(pa.gx.precon[i]))
			storage[i]=0.0
		else
			storage[i]=pa.optm.dg[i]/pa.gx.precon[i]
		end
	end
	return storage
end



function initialize!(pa::BD)
	# starting random models
	for i in eachindex(pa.optm.cal.s)
		x=(pa.sx.precon[i]≠0.0) ? randn() : 0.0
		if(STF_FLAG)
			pa.optm.cal.s[i]=abs(x)
		else
			pa.optm.cal.s[i]=x
		end
	end
	for i in eachindex(pa.optm.cal.g)
		x=(pa.gx.precon[i]≠0.0) ? randn() : 0.0
		pa.optm.cal.g[i]=x
	end
end






"""
compute errors
update pa.err
print?
give either cal 
"""
function err!(pa::BD, io=stdout; cal=pa.optm.cal) 
	xg_nodecon=hcat(Conv.xcorr(pa.om.d,Conv.P_xcorr(pa.om.nt, pa.om.nr, cglags=[pa.optm.ntg-1, pa.optm.ntg-1]))...)
	xgobs=hcat(Conv.xcorr(pa.om.g)...) # compute xcorr with reference g
	fs = Misfits.error_after_normalized_autocor(cal.s, pa.optm.obs.s)
	xgcal=hcat(Conv.xcorr(cal.g)...) # compute xcorr with reference g
	fg = Misfits.error_squared_euclidean!(nothing, xgcal, xgobs, nothing, norm_flag=true)
	fg_nodecon = Misfits.error_squared_euclidean!(nothing, xg_nodecon, xgobs, nothing, norm_flag=true)
	f = Misfits.error_squared_euclidean!(nothing, cal.d, pa.optm.obs.d, nothing, norm_flag=true)

	whiteness=Conv.func_grad!(nothing, cal.g, Conv.P_misfit_weighted_acorr(pa.om.ntg,pa.om.nr))

	front_load=Misfits.front_load!(nothing, cal.g)

	push!(pa.err[:s],fs)
	push!(pa.err[:d],f)
	push!(pa.err[:g],fg)
	push!(pa.err[:whiteness],whiteness)
	push!(pa.err[:front_load],front_load)
	push!(pa.err[:g_nodecon],fg_nodecon)
	write(io,"Blind Decon Errors\t\n")
	write(io,"==================\n")
	write(io, string(pa.err))
end 

function update_g!(pa::BD, xg)
	pa.attrib_inv=:g    
	fg = update!(pa, xg)
	return fg
end

function update_s!(pa::BD, xs)
	pa.attrib_inv=:s    
	fs = update!(pa, xs)
	return fs
end




#=
struct BandLimit <: Manifold
end

function retract!(::BandLimit,x)
	#=
	x_to_model!(x, pa) # modify pa.optm.cal.s or pa.optm.cal.g

	pac=pa.optm.cal
	if(pa.attrib_inv==:g)
	Conv.pad_truncate!(pac.g, pac.gpad, pac.glags[1], pac.glags[2], pac.np2, 1)
	A_mul_B!(pac.gfreq, pac.gfftp, pac.gpad)

	nr=pa.om.nr
	for ir in 1:nr
		for i in 1:10
			pac.gfreq[i,ir]=complex(0.0,0.0)
		end
	end
	A_mul_B!(pac.gpad, pac.gifftp, pac.gfreq)
	Conv.pad_truncate!(pac.g, pac.gpad, pac.glags[1], pac.glags[2], pac.np2, -1)
	=#
end
export retract!

function project_tangent!(::BandLimit,g,x)

end
=#
