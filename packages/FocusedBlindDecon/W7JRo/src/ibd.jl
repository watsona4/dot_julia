
"""
* `sxp` : how to create the inversion vector for sa?
   * =:positive  only positive lags 
   * =:all all lags  
"""
mutable struct IBD{T}
	om::ObsModel{T}
	optm::OptimModel{T}
	gx::X{T}
	sx::X{T}
	sxp::Sxparam
	sx_fix_zero_lag_flag::Bool
	attrib_inv::Symbol
	verbose::Bool
	err::DataFrames.DataFrame
	opG::LinearMaps.LinearMap{T}
	opS::LinearMaps.LinearMap{T}
	pbandpassG::P_bandpass{T}
	pbandpassS::P_bandpass{T}
end



"""
`gprecon` : a preconditioner applied to each Greens functions [ntg]
"""
function IBD(ntg, nt, nr, nts;
	       fft_threads=true,
	       fftwflag=FFTW.PATIENT,
	       sxp=Sxparam(1,:positive),
	       sx_fix_zero_lag_flag=true,
	       dobs=nothing, 
	       gobs=nothing, 
	       sobs=nothing, 
	       verbose=false,
	       fmin=0.15,
	       fmax=0.45,
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

	# use maximum threads for fft only for patient
	fft_threads &&  (FFTW.set_num_threads(Sys.CPU_THREADS))

	# store observed data
	om=ObsModel(ntg, nt, nr, nts, T, d=dobs, g=gobs, s=sobs)

	# create interferometric Optim 
	optm=OptimModel(2*ntg-1, 2*nt-1, binomial(nr, 2)+nr, 2*nts-1, T, fftwflag=fftwflag, 
	slags=[nts-1, nts-1], 
	dlags=[nt-1, nt-1], 
	glags=[ntg-1, ntg-1], 
		 )
		
	# inversion variables allocation
	gx=X(length(optm.cal.g),T)

	if(sxp.attrib==:positive)
		if(sx_fix_zero_lag_flag)
			sx=X(nts-1,T) # not including zero lag
		else
			sx=X(nts,T) 
		end
	elseif(sxp.attrib==:all)
		if(sx_fix_zero_lag_flag)
			sx=X(length(optm.cal.s)-1,T) # not including zero lag
		else
			sx=X(length(optm.cal.s),T)
		end
	else
		error("invalid sxp")
	end

	err=DataFrame(g=[], g_nodecon=[], s=[], d=[], whiteness_obs=[], whiteness_cal=[])


	# dummy
	opG=LinearMap{T}(x->0.0, y->0.0,1,1, ismutating=true)
	opS=LinearMap{T}(x->0.0, y->0.0,1,1, ismutating=true)


	pbandpassG=DC.P_bandpass(T, fmin=fmin, fmax=fmax, nt=optm.ntg)
	pbandpassS=DC.P_bandpass(T, fmin=fmin, fmax=fmax, nt=optm.nts)


	pa=IBD{T}(om, optm, gx, sx, sxp, sx_fix_zero_lag_flag, 
	:g, verbose, err, opG, opS, pbandpassG, pbandpassS)


	# update operators
	pa.opG=create_operator(pa, G())
	pa.opS=create_operator(pa, S())

	#=
	if(sx_fix_zero_lag_flag)
		if(sxp==:positive)
			# adjust sprecon
			pa.sx.precon[1]=0.0 # do not update zero lag
			pa.sx.preconI[1]=0.0 # do not update zero lag
		elseif(sxp==:all)
			pa.sx.precon[nts]=0.0 # do not update zero lag
			pa.sx.preconI[nts]=0.0 # do not update zero lag
		else
			error("invalid sxp")
		end
	end
	=#
 
	gobs=hcat(Conv.xcorr(pa.om.g)...)
	sobs=hcat(Conv.xcorr(pa.om.s)...)

	# obs.g <-- gobs
	replace!(pa.optm, gobs, :obs, :g )
	# obs.s <-- sobs
	replace!(pa.optm, sobs, :obs, :s )
	# obs.d <-- dobs
	dobs=hcat(Conv.xcorr(pa.om.d)...) # do a cross-correlation 

	copyto!(pa.optm.obs.d, dobs) # overwrites the forward modelling done in previous steps  

	# normalize the observed data to 1.0
	rmul!(pa.optm.obs.d, inv(maximum(pa.optm.obs.d)))

	initialize!(pa)

	return pa
	
end


function update_prepare!(pa::IBD, ::S)
	# fixing zero lag of source is equivalent to fitting d-g, for sxp.n==1	
	# note that it is necessary while using IterativeSolvers.jl
	if(isequal(pa.sxp.n,1) && pa.sx_fix_zero_lag_flag)
		for ir in 1:pa.optm.nr
			for it in 1:pa.optm.ntg
				pa.optm.obs.d[pa.om.nt-pa.om.ntg+it,ir] -= pa.optm.cal.g[it,ir]
			end
		end
	end
end
function update_prepare!(pa::IBD, ::G)
	if(isequal(pa.sxp.n,1) && pa.sx_fix_zero_lag_flag)
		pa.optm.cal.s[pa.om.nts]=1.0
	end
end
function update_finalize!(pa::IBD, ::S)
	# add g back to d, after optimizing s
	if(isequal(pa.sxp.n,1) && pa.sx_fix_zero_lag_flag)
		for ir in 1:pa.optm.nr
			for it in 1:pa.optm.ntg
				pa.optm.obs.d[pa.om.nt-pa.om.ntg+it,ir] += pa.optm.cal.g[it,ir]
			end
		end
	end

	if(FILT_FLAG)
		# put sa[0]=1.0, before filtering
		if(isequal(pa.sxp.n,1) && pa.sx_fix_zero_lag_flag)
			pa.optm.cal.s[pa.om.nts]=1.0
		end
		bp=create_operator(pa.pbandpassS)
		copyto!(pa.optm.ds,pa.optm.cal.s)
		mul!(pa.optm.sfilt, bp, pa.optm.cal.s)
		copyto!(pa.optm.cal.s,pa.optm.sfilt)
		# 
		if(isequal(pa.sxp.n,1) && pa.sx_fix_zero_lag_flag)
			pa.optm.cal.s[pa.om.nts]=0.0
		end
	end


	if(STF_FLAG)
		for i in eachindex(pa.optm.cal.s)
			if(pa.optm.cal.s[i] <0.0)
				pa.optm.cal.s[i]=0.0
			end
		end
	end
end
function update_finalize!(pa::IBD, ::G)
	if(isequal(pa.sxp.n,1) && pa.sx_fix_zero_lag_flag)
		pa.optm.cal.s[pa.om.nts]=0.0
	end


	if(FILT_FLAG)
		bp=create_operator(pa.pbandpassG)
		copyto!(pa.optm.dg,pa.optm.cal.g)
		mul!(pa.optm.gfilt, bp, pa.optm.cal.g)
		copyto!(pa.optm.cal.g,pa.optm.gfilt)

		# put back for autocorr, if focusing
		if(minimum(pa.gx.preconI) == 0.0)
			irr=1  # auto correlation index
			for ir in 1:pa.om.nr
				gcopyv=view(pa.optm.dg,:,irr)
				gv=view(pa.optm.cal.g, :, irr)
				copyto!(gv, gcopyv)
				irr+=pa.om.nr-(ir-1)
			end
		end
	end
end

function model_to_x!(x, pa::IBD, ::S)
	if(pa.sxp.attrib==:all)
		if(pa.sx_fix_zero_lag_flag)
			nts=pa.om.nts
			for i in 1:nts-1
				x[i]=^(pa.optm.cal.s[i],inv(pa.sxp.n))*pa.sx.precon[i] 
			end
			for i in nts+1:2*nts-1
				x[i-1]=^(pa.optm.cal.s[i],inv(pa.sxp.n))*pa.sx.precon[i-1] 
			end
		else
			for i in eachindex(x)
				x[i]=^(pa.optm.cal.s[i],inv(pa.sxp.n))*pa.sx.precon[i] 
			end
		end
	elseif(pa.sxp.attrib==:positive)
		if(pa.sx_fix_zero_lag_flag)
			for i in eachindex(x)
				x[i]=^(pa.optm.cal.s[pa.om.nts+i],inv(pa.sxp.n))*pa.sx.precon[i] # just take positive lags
			end
		else
			for i in eachindex(x)
				x[i]=^(pa.optm.cal.s[i+pa.om.nts-1],inv(pa.sxp.n))*pa.sx.precon[i] # just take positive lags
			end
		end
	else	
		error("invalid sxp")
	end
	return nothing
end
function model_to_x!(x, pa::IBD, ::G)
	for i in eachindex(x)
		x[i]=pa.optm.cal.g[i]*pa.gx.precon[i] 		# multiply by gprecon
	end
	return nothing
end


function x_to_model!(x, pa::IBD, ::S)
	if(pa.sxp.attrib==:all)
		if(pa.sx_fix_zero_lag_flag)
			for i in 1:pa.om.nts-1
				pa.optm.cal.s[i]=^(x[i],pa.sxp.n)*pa.sx.preconI[i]
			end
			for i in pa.om.nts+1:2*pa.om.nts-1
				pa.optm.cal.s[i]=^(x[i-1],pa.sxp.n)*pa.sx.preconI[i-1]
			end
			if(isequal(pa.sxp.n,1))
				pa.optm.cal.s[pa.om.nts]=0.0
			else
				pa.optm.cal.s[pa.om.nts]=1.0
			end

		else
			for i in eachindex(pa.optm.cal.s)
				pa.optm.cal.s[i]=^(x[i],pa.sxp.n)*pa.sx.preconI[i]
			end
		end
	elseif(pa.sxp.attrib==:positive)
		if(pa.sx_fix_zero_lag_flag)
			for i in 1:pa.om.nts-1
				# put same in positive lags
				pa.optm.cal.s[pa.om.nts+i]=^(x[i],pa.sxp.n)*pa.sx.preconI[i]
				# put same in negative lags
				pa.optm.cal.s[pa.om.nts-i]=^(x[i],pa.sxp.n)*pa.sx.preconI[i]
			end
			if(isequal(pa.sxp.n,1))
				pa.optm.cal.s[pa.om.nts]=0.0
			else
				pa.optm.cal.s[pa.om.nts]=1.0
			end
		else
			for i in 1:pa.om.nts-1
				# put same in positive lags
				pa.optm.cal.s[pa.om.nts+i]=^(x[i+1],pa.sxp.n)*pa.sx.preconI[i+1]
				# put same in negative lags
				pa.optm.cal.s[pa.om.nts-i]=^(x[i+1],pa.sxp.n)*pa.sx.preconI[i+1]
			end
			pa.optm.cal.s[pa.om.nts]=^(x[1],pa.sxp.n)*pa.sx.preconI[1]
		end
	else
		error("invalid sxp")
	end
	return pa
end

function x_to_model!(x, pa::IBD, ::G)
	for i in eachindex(pa.optm.cal.g)
		pa.optm.cal.g[i]=x[i]*pa.gx.preconI[i]
	end
	return pa
end


"""
Zero out elements of g_ii, depending on nlags
"""
function focus!(pa::IBD, nlags=1)
	nr=pa.om.nr
	ntg=pa.om.ntg
	irr=1  # auto correlation index
	for ir in 1:nr
		for i in nlags:ntg-1    
			# zero out Greens functions at non zero lags
			pa.optm.cal.g[ntg+i,irr]=0.0
			pa.optm.cal.g[ntg-i,irr]=0.0
		end
		irr+=nr-(ir-1)
	end

end


"""
Add a preconditioner to update only a few lags of the g_ii
Total lags that the precon is non-zero is given by 2*nlags-1
"""
function add_focusing_gprecon!(pa::IBD, nlags=1; k=1.0)

	nr=pa.om.nr
	ntg=pa.om.ntg
	gprecon=ones(pa.optm.ntg, pa.optm.nr).*k; 

	irr=1  # auto correlation index
	for ir in 1:nr
		for i in nlags:ntg-1    
			gprecon[ntg+i,irr]=0.0    # put zero at +ve lags
			gprecon[ntg-i,irr]=0.0    # put zero at -ve lags
		end
		gprecon[ntg,irr]=1.0    # put zero at -ve lags
		irr+=nr-(ir-1)
	end
	add_gprecon!(pa, gprecon)
	return pa
end

"""
Add a preconditioner to update only g_ii without focusing
"""
function add_autocorr_gprecon!(pa::IBD)

	nr=pa.om.nr
	ntg=pa.om.ntg
	gprecon=zeros(pa.optm.ntg, pa.optm.nr); 

	irr=1  # auto correlation index
	for ir in 1:nr
		gprecon[:,irr]=1.0    # put one
		irr+=nr-(ir-1)
	end
	add_gprecon!(pa, gprecon)
	return pa
end


"""
Add focusing in pa.
Zero out pa.optm.cal.g for autocorrelations and non zero lags
"""
function add_focusing_gweights!(pa::IBD)

	nr=pa.om.nr
	ntg=pa.om.ntg
	gweights=zeros(pa.optm.ntg, pa.optm.nr); 

	irr=1  # auto correlation index
	for ir in 1:nr
		for i in 1:ntg-1
			gweights[ntg+i,irr]=abs((i)/(ntg-1))
			gweights[ntg-i,irr]=abs((i)/(ntg-1))
		end
		irr+=nr-(ir-1)
	end
	add_gweights!(pa, gweights)
	return pa
end



"""
compute the amount of focusing in cross-correlated g
"""
function whiteness_focusing(pa::IBD, attrib=:obs)
	g=getfield(pa.optm, attrib).g
	nr=pa.om.nr
	ntg=pa.om.ntg

	irr=1  # auto correlation index
	J = 0.0
	for ir in 1:nr
		gg=view(g, :, irr)
		JJ = 0.0
		fact=inv(gg[ntg]*gg[ntg])
		for i in eachindex(gg)
			JJ += gg[i] * gg[i] * fact  * abs((ntg-i)/(ntg    -1))

		end
		J += JJ
		irr+=nr-(ir-1)
	end
	J = J * inv(nr) # scale with number of receivers
	return J
end

function ibd!(pa::IBD, io=stdout)

	remove_gprecon!(pa, including_zeros=true)  # remove precon
	remove_gweights!(pa, including_zeros=true)
	#update_func_grad!(pa,goptim=[:ls,], gαvec=[1.]); 
	update_all!(pa, io, max_reroundtrips=1, max_roundtrips=100000, roundtrip_tol=1e-8)

	err!(pa)
end



"""
Focused Blind Deconvolution
"""
function fibd!(pa::IBD, io=stdout; verbose=true, α=[Inf, 0.0], tol=[1e-10,1e-4])

	if(io===nothing)
		logfilename=joinpath(pwd(),string("XFIBD",Dates.now(),".log"))
		io=open(logfilename, "a+")
	end

	updates = (x,y) -> update_all!(pa, io,                   
				    max_reroundtrips=1, max_roundtrips=y, 
				    roundtrip_tol=x, verbose=true)

	add_focusing_gweights!(pa) # adds weights
	for (iα, αv) in enumerate(α)
		write(io, string("## (",iα,"/",length(α),") homotopy for alpha=", αv,"\n"))
		# if set α=∞ 
		if(αv==Inf)
			focus!(pa)
			add_focusing_gprecon!(pa) # adds precon
			#update_func_grad!(pa,goptim=[:ls,], gαvec=[1.]); 
			updates(tol[iα], 10000000)
			#add_autocorr_gprecon!(pa) # adds precon
			#updates(tol[iα])
			remove_gprecon!(pa, including_zeros=true)  # remove precon
		elseif(αv==0.0)
			remove_gprecon!(pa, including_zeros=true)  # remove precon
			remove_gweights!(pa, including_zeros=true)
			#update_func_grad!(pa,goptim=[:ls,], gαvec=[1.]); 
			updates(tol[iα], 500)
		else
			error("not functional for arbitary alpha")
			remove_gprecon!(pa, including_zeros=true)  # remove precon
			add_focusing_gweights!(pa) # adds weights
			#update_func_grad!(pa,goptim=[:ls, :weights], gαvec=[1., αv]); 
			updates(tol[iα])
		end
	end
	remove_gweights!(pa, including_zeros=true)
	err!(pa)
end


function initialize!(pa::IBD, all_zero=false)
	for i in eachindex(pa.optm.cal.s)
		pa.optm.cal.s[i]= ^(abs.(randn()),(pa.sxp.n-1)) # zero for sxp.n==1, otherwise randn
	end
#	pa.optm.cal.s[pa.om.nts]=1.0 # initialize zero lag to one
	if(all_zero)
		pa.optm.cal.g[:]=0.0
	else
		for i in eachindex(pa.optm.cal.g)
			x=(pa.gx.precon[i]≠0.0) ? randn() : 0.0
			pa.optm.cal.g[i]=x
		end
	end
end


function F!(pa::IBD,	x::AbstractVector, attrib::S)
	compute=(x!=pa.sx.last_x)
	if(compute)
		x_to_model!(x, pa, attrib) # modify pa.optm.cal.s 
		copyto!(pa.sx.last_x, x)
		Conv.mod!(pa.optm.cal, Conv.D()) # modify pa.optm.cal.d
		return pa
	end
end

function F!(pa::IBD,	x::AbstractVector, ::G)
	compute=(x!=pa.gx.last_x)
	if(compute)
		x_to_model!(x, pa, G()) # modify pa.optm.cal.g
		copyto!(pa.gx.last_x, x)
		Conv.mod!(pa.optm.cal, Conv.D()) # modify pa.optm.cal.d
		return pa
	end
end



"""
Apply Fadj to dcal and return storage
"""
function Fadj!(pa::IBD, storage, x, dcal, ::S)
	fill!(storage, 0.)
	Conv.mod!(pa.optm.cal, Conv.S(), d=dcal, s=pa.optm.ds)
	if(pa.sxp.attrib == :positive)
		# stacking over +ve and -ve lags
		if(pa.sx_fix_zero_lag_flag)
			for j in 2:pa.om.nts
				storage[j-1] += pa.optm.ds[pa.om.nts-j+1] # -ve lags
				storage[j-1] += pa.optm.ds[pa.om.nts+j-1] # +ve lags
			end
		else
			for j in 2:pa.om.nts
				storage[j] += pa.optm.ds[pa.om.nts-j+1] # -ve lags
				storage[j] += pa.optm.ds[pa.om.nts+j-1] # +ve lags
			end
			storage[1]=pa.optm.ds[pa.om.nts]
		end
	elseif(pa.sxp.attrib == :all)
		if(pa.sx_fix_zero_lag_flag)
			nts=pa.om.nts
			for i in 1:nts-1
				storage[i] = pa.optm.ds[i] #
			end
			for i in nts+1:2*nts-1
				storage[i-1] = pa.optm.ds[i] #
			end
		else
			for i in eachindex(storage)
				storage[i] = pa.optm.ds[i] #
			end
		end
	else
		error("invalid attrib" )
	end
	# apply precon
	for i in eachindex(storage)
		if(iszero(pa.sx.precon[i]))
			storage[i]=0.0
		else
			storage[i] = storage[i]*pa.sxp.n*^(x[i],pa.sxp.n-1)*pa.sx.preconI[i]
		end
	end
end

function Fadj!(pa::IBD, storage, x, dcal, ::G)
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

#=

"""
Force real and non negative spectrum for g
"""
function weak_autocorr_constraint_g!(g, pac)
	Conv.pad!(g, pac.gpad, pac.glags[1], pac.glags[2], pac.np2)
	A_mul_B!(pac.gfreq, pac.gfftp, pac.gpad)
	ntot=1
	nr=size(pac.gfreq,2)
	for ir in 1:nr
		for i in size(pac.gfreq,1)
			pac.gfreq[i,ntot]=complex(real(pac.gfreq[i,ntot]),0.0)
			if(real(pac.gfreq[i,ntot]) < 0.0)
				pac.gfreq[i,ntot]=complex(0.0,0.0)
			end
		end
		ntot += (nr-ir+1)
	end
	A_mul_B!(pac.gpad, pac.gifftp, pac.gfreq)
	Conv.truncate!(g, pac.gpad, pac.glags[1], pac.glags[2], pac.np2)
end


"""
Force real and non negative spectrum for s
"""
function weak_autocorr_constraint_s!(s, pac)
	Conv.pad!(s, pac.spad, pac.slags[1], pac.slags[2], pac.np2)
	A_mul_B!(pac.sfreq, pac.sfftp, pac.spad)
	for i in eachindex(pac.sfreq)
		pac.sfreq[i]=complex(real(pac.sfreq[i]),0.0)
		if(real(pac.sfreq[i]) < 0.0)
			pac.sfreq[i]=complex(0.0,0.0)
		end
	end
	A_mul_B!(pac.spad, pac.sifftp, pac.sfreq)
	Conv.truncate!(s, pac.spad, pac.slags[1], pac.slags[2], pac.np2)
end
=#


"""
The cross-correlated Green's functions and the auto-correlated source signature have to be reconstructed exactly, except for a scaling factor.
"""
function err!(pa::IBD, io=stdout; cal=pa.optm.cal) 
	(fg, b)	= Misfits.error_after_scaling(cal.g, pa.optm.obs.g) # error upto a scalar b
	(fs, b)	= Misfits.error_after_scaling(cal.s, pa.optm.obs.s) # error upto a scalar b
	f = Misfits.error_squared_euclidean!(nothing, cal.d, pa.optm.obs.d, nothing, norm_flag=true)

	xg_nodecon=hcat(Conv.xcorr(pa.om.d,Conv.P_xcorr(pa.om.nt, pa.om.nr, cglags=[pa.om.ntg-1, pa.om.ntg-1]))...)
	xgobs=hcat(Conv.xcorr(pa.om.g)...) # compute xcorr with reference g
	fg_nodecon = Misfits.error_squared_euclidean!(nothing, xg_nodecon, xgobs, nothing, norm_flag=true)

	push!(pa.err[:whiteness_obs], whiteness_focusing(pa, :obs))
	push!(pa.err[:whiteness_cal], whiteness_focusing(pa, :cal))

	push!(pa.err[:s],fs)
	push!(pa.err[:d],f)
	push!(pa.err[:g],fg)
	push!(pa.err[:g_nodecon],fg_nodecon)
	write(io,"Interferometric Blind Decon Errors\t\n")
	write(io,"==================\n")
	if(io==stdout)
		display(pa.err)
	else
		write(io, string(pa.err))
	end
	write(io, "\n")
end 

