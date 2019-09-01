
mutable struct Param{T}
	pfibd::IBD{T}
	pfpr::FPR
	plsbd::BD{T}
end


function Param(ntg, nt, nr, nts;
	       dobs=nothing, 
	       gobs=nothing, 
	       sobs=nothing, 
	       sxp=Sxparam(1,:positive),
	       fmin=0.0,
	       fmax=0.5,
	       ) 
	pfibd=IBD(ntg, nt, nr, nts, gobs=gobs, dobs=dobs, sobs=sobs, 
		  fft_threads=true, fftwflag=FFTW.MEASURE,
		  verbose=false, sxp=sxp, sx_fix_zero_lag_flag=true, fmin=fmin, fmax=fmax);

	pfpr=FPR(ntg, nr)

	plsbd=BD(ntg, nt, nr, nts, dobs=dobs, gobs=gobs, sobs=sobs, 
	  sxp=sxp,
		 fft_threads=true, verbose=false, fftwflag=FFTW.MEASURE);

	return Param(pfibd, pfpr, plsbd)

end


function fbd!(pa::Param, io=stdout; tasks=[:restart, :fibd, :fpr, :updateS], fibd_tol=[1e-10,1e-6])

	if(:restart ∈ tasks)
		# initialize
		initialize!(pa.pfibd)
	end

	if(:fibd ∈ tasks)
		# start with fibd
		fibd!(pa.pfibd, io, α=[Inf],tol=[fibd_tol[1]])
		fibd!(pa.pfibd, io, α=[0.0],tol=[fibd_tol[2]])
	end

	# input g from fibd to fpr
	gobs = (iszero(pa.pfibd.om.g)) ? nothing : pa.pfibd.om.g # choose gobs for nearest receiver or not?
	update_cymat!(pa.pfpr; cymat=pa.pfibd.optm.cal.g, gobs=gobs)

	# perform fpr
	g=pa.plsbd.optm.cal.g
	Random.randn!(g)

	if(:fpr ∈ tasks)
		fpr!(g,  pa.pfpr, precon=:focus)
	end

	if(:updateS ∈ tasks)
		# update source according to the estimated g from fpr
		if(STF_FLAG)
			update_stf!(pa.plsbd)
		else
			update!(pa.plsbd, pa.plsbd.sx.x, S(), optS)
		end
	end

	# regular lsbd: do a few more AM steps? might diverge..
	if(:lsbd ∈ tasks)
		bd!(pa.plsbd, io; tol=1e-5)
	end

	return nothing
end



function random_problem()

	ntg=3
	nr=50
	tfact=10
	gobs=randn(ntg, nr)
	nt=ntg*tfact
	nts=nt-ntg+1;
	sobs=randn(nts)
	sxp=Sxparam(1,:positive)
	if(STF_FLAG)
		sobs=abs.(sobs);
	end
	return Param(ntg, nt, nr, nts, gobs=gobs, sobs=sobs,sxp=sxp)
end


function simple_problem()

	ntg=30
	nr=20
	tfact=20
	gobs=zeros(ntg, nr)
	Signals.toy_direct_green!(gobs, c=4.0, bfrac=0.20, afrac=1.0);
	#Signals.toy_direct_green!(gobs, c=4.0, bfrac=0.4, afrac=1.0);
	Signals.toy_reflec_green!(gobs, c=1.5, bfrac=0.35, afrac=-0.6);
	#Signals.toy_reflec_green!(gobs, c=1.5, bfrac=0.35, afrac=1.0);
	nt=ntg*tfact
	nts=nt-ntg+1;
	sobs=(randn(nts));
	return Param(ntg, nt, nr, nts, gobs=gobs, sobs=sobs,sxp=Sxparam(1,:positive))
end

function simple_bandlimited_problem(fmin=0.1, fmax=0.4)
	pa=simple_problem()

	dobs=pa.plsbd.om.d
	responsetype = Bandpass(fmin,fmax; fs=1)
	designmethod = Butterworth(8)
	# zerophase filter please
	dobs_filt=DSP.Filters.filtfilt(digitalfilter(responsetype, designmethod), dobs)

	# filter dobs
	pom=pa.plsbd.om
	return Param(pom.ntg, pom.nt, pom.nr, pom.nts, dobs=dobs_filt, 
	    gobs=pom.g, sobs=pom.s,sxp=Sxparam(1,:positive), fmin=fmin, fmax=fmax)

end

#Source Time Functions are always positive
function simple_STF_problem()

	ntg=30
	nr=20
	tfact=20
	gobs=zeros(ntg, nr)
	Signals.toy_direct_green!(gobs, c=4.0, bfrac=0.20, afrac=1.0);
	#Signals.toy_direct_green!(gobs, c=4.0, bfrac=0.4, afrac=1.0);
	Signals.toy_reflec_green!(gobs, c=1.5, bfrac=0.35, afrac=-0.6);
	#Signals.toy_reflec_green!(gobs, c=1.5, bfrac=0.35, afrac=1.0);
	nt=ntg*tfact
	nts=nt-ntg+1;
	sobs=abs.(randn(nts));
	return Param(ntg, nt, nr, nts, gobs=gobs, sobs=sobs, sxp=Sxparam(2,:positive))
end
