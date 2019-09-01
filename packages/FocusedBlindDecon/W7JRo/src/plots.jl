

@userplot Plotoptimmodel

@recipe function f(p::Plotoptimmodel; rvec=nothing, δt=1.0, attrib=:obs)
	pa=p.args[1]
	(rvec===nothing) && (rvec=1:pa.nr)



	#=


	gxobs=zeros(2*size(pa.obs.g,1)-1, size(pa.obs.g,2))
	gxcal=similar(gxobs)
	scobs=vecnorm(pa.obs.g[:,1])^2
	sccal=vecnorm(pa.cal.g[:,1])^2
	for ir in 1:pa.nr
		gxobs[:,ir] = xcorr(pa.obs.g[:,1], pa.obs.g[:, ir])/scobs
		gxcal[:,ir] = xcorr(pa.cal.g[:,1], pa.cal.g[:, ir])/sccal
	end
	#
	g=collect(1:pa.ntg)*δt
	gx=collect(-pa.ntg+1:1:pa.ntg-1)*δt

	# time vectors
	# autocorr s
	asobs=autocor(pa.obs.s[:,1], 1:pa.nt-1, demean=true)
	as=autocor(pa.cal.s[:,1], 1:pa.nt-1, demean=true)
	sli=max(maximum(abs,asobs), maximum(abs,as))
	# autocorr g 
	agobs=autocor(pa.obs.g,1:pa.ntg-1, demean=true)
	ag=autocor(pa.cal.g,1:pa.ntg-1, demean=true)
	gli=max(maximum(abs,agobs), maximum(abs,ag))

#	asobs=asobs[1:fact:ns] # resample
#	as=as[1:fact:ns] # resample

	#fact=(pa.nt*pa.nr>1000) ? round(Int,pa.nt*pa.nr/1000) : 1
	# cut receivers
#	dcal=pa.cal.d[1:fact:pa.nt*pa.nr]
#	dobs=pa.obs.d[1:fact:pa.nt*pa.nr]

=#

	if((attrib==:obs) || (attrib==:cal))
		layout := (3,1)
		g=getfield(pa,attrib).g
		s=getfield(pa,attrib).s
		temp=getfield(pa,attrib)
		dd=getfield(temp, fieldnames(temp)[5])

		ns=length(s)
		fact=(ns>1000) ? round(Int,ns/1000) : 1
		fnrp=(pa.nr>10) ? round(Int,pa.nr/10) : 1

		@series begin        
			subplot := 1
	#		aspect_ratio := :auto
			legend := false
	#		l := :plot
			title := string("\$g_i\$ ", attrib)
			w := 1
			g[:,1:fnrp:end]
		end
		@series begin        
			subplot := 2
	#		aspect_ratio := :auto
			legend := false
			title := string("\$s\$ ", attrib)
			w := 1
			s[1:fact:end,1]
		end
		@series begin        
			subplot := 3
	#		aspect_ratio := :auto
			legend := false
			title := string("\$d_i\$ ", attrib)
			w := 1
			dd[1:fact:end,1:fnrp:end]
		end
	end


	if(attrib==:x)
		ns=length(pa.nt)
		fact=(ns>1000) ? round(Int,ns/1000) : 1

		fnrp=(pa.nr>10) ? round(Int,pa.nr/10) : 1

		xsobs=pa.obs.s[1:fact:end,1]
		xscal=pa.cal.s[1:fact:end,1]
		xdcal=getfield(pa.cal,fieldnames(pa.cal)[5])[1:fact*pa.nr:end]
	        xdobs=getfield(pa.obs,fieldnames(pa.obs)[5])[1:fact*pa.nr:end]
		xgcal=pa.cal.g[:,1:fnrp:end][:]
		xgobs=pa.obs.g[:,1:fnrp:end][:]
		layout := (1,3)
		@series begin        
			subplot := 1
			aspect_ratio := :equal
			seriestype := :scatter
			title := "scatter s"
			legend := false
			normalize(xsobs), normalize(xscal)
		end
		@series begin        
			subplot := 2
			aspect_ratio := :equal
			seriestype := :scatter
			title := "scatter g"
			legend := false
			normalize(xgobs), normalize(xgcal)
		end

		@series begin        
			subplot := 3
			aspect_ratio := :equal
			seriestype := :scatter
			title := "scatter d"
			legend := false
			normalize(xdobs), normalize(xdcal)
		end
	end

	if(attrib==:precon)
		layout := (3,1)
		@series begin        
			subplot := 1
	#		aspect_ratio := :auto
			legend := false
			title := "gprecon"
			w := 1
			pa.gprecon
		end
		@series begin        
			subplot := 2
	#		aspect_ratio := :auto
			legend := false
			title := "sprecon"
			w := 1
			pa.sprecon
		end
		@series begin        
			subplot := 3
	#		aspect_ratio := :auto
			legend := false
			title := "gweights"
			w := 1
			pa.gweights
		end




	end
end



@userplot Plotobsmodel

@recipe function f(p::Plotobsmodel; rvec=nothing, δt=1.0)
	pa=p.args[1]
	layout := (3,1)

	tg=collect(1:pa.ntg)*δt
	td=collect(1:pa.nt)*δt

	@series begin        
		subplot := 1
#		aspect_ratio := :auto
		legend := false
#		l := :plot
		title := "\$g_i\$"
		w := 1
		tg, pa.g
	end
	@series begin        
		subplot := 2
#		aspect_ratio := :auto
		legend := false
		title := "\$s\$"
		w := 1
		td, pa.s
	end
	@series begin        
		subplot := 3
#		aspect_ratio := :auto
		legend := false
		title := "\$d_i\$"
		w := 1
		td, getfield(pa,fieldnames(pa)[6])
	end
end


@userplot Plotprmodel

@recipe function f(p::Plotprmodel; gobs=nothing, rvec=nothing, δt=1.0, attrib=:obs)
	pa=p.args[1]
	nr=size(pa.g,2)
	ntg=size(pa.g,1)
	(rvec===nothing) && (rvec=1:nr)

	layout := (3,2)
	g1=pa.g
	if(gobs===nothing)
		gobs=zeros(g1)
	end
	dd0=hcat(pa.p_misfit_xcorr.cy...)
	dd=hcat(pa.p_misfit_xcorr.pxcorr.cg...)

	nr1=size(dd,2)
	ns=size(dd,1)
	fact=(ns>1000) ? round(Int,ns/1000) : 1
	fnrp=(nr1>10) ? round(Int,nr1/10) : 1

	@series begin        
		subplot := 1
#		aspect_ratio := :auto
		legend := false
#		l := :plot
		title := string("\$g_i\$ ", "obs")
		w := 1
		gobs
	end
	@series begin        
		subplot := 2
#		aspect_ratio := :auto
		legend := false
#		l := :plot
		title := string("\$g_i\$ ", "cal")
		w := 1
		g1
	end
	@series begin        
		subplot := 3
#		aspect_ratio := :auto
		legend := false
		title := string("\$d_i\$ ", "obs")
		w := 1
		dd0[1:fact:end,1:fnrp:end]
	end
	@series begin        
		subplot := 4
#		aspect_ratio := :auto
		legend := false
		title := string("\$d_i\$ ", "cal")
		w := 1
		dd[1:fact:end,1:fnrp:end]
	end

	xdcal=dd[1:fact*nr1:end]
	xdobs=dd0[1:fact*nr1:end]
	@series begin        
		subplot := 5
		aspect_ratio := :equal
		seriestype := :scatter
		title := "scatter d"
		legend := false
		normalize(xdobs), normalize(xdcal)
	end
end


