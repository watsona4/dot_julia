# methods common to IBD and BD


ninv(pa, ::S) = length(pa.sx.x)
ninv(pa, ::G) = length(pa.gx.x)


function add_gprecon!(pa, gprecon)

	copyto!(pa.gx.precon, gprecon)		
	copyto!(pa.gx.preconI, pa.gx.precon)
	for i in eachindex(gprecon)
		if(!(iszero(gprecon[i])))
			pa.gx.preconI[i]=inv(pa.gx.precon[i])
		end
	end
end
function add_sprecon!(pa, sprecon)
	copyto!(pa.sx.precon, sprecon)
	copyto!(pa.sx.preconI, pa.sx.precon)
	for i in eachindex(sprecon)
		if(!(iszero(sprecon[i])))
			pa.sx.preconI[i]=inv(pa.sx.precon[i])
		end
	end
end
function add_gweights!(pa, gweights)
	(gweights===nothing) && (gweights=ones(pa.optm.cal.g))
	copyto!(pa.gx.weights, gweights)
end


# Remove preconditioners from pa
function remove_gprecon!(pa; including_zeros=false)
	for i in eachindex(pa.gx.precon)
		if((pa.gx.precon[i]≠0.0) || including_zeros)
			pa.gx.precon[i]=1.0
			pa.gx.preconI[i]=1.0
		end
	end
end

"""
Remove weights from pa
"""
function remove_gweights!(pa; including_zeros=false)
	for i in eachindex(pa.gx.weights)
		if((pa.gx.weights[i]≠0.0) || including_zeros)
			pa.gx.weights[i]=1.0
		end
	end
end




# these are not use at this moment

#=
function update_window!(paf::FourierConstraints, obs)
	pac=obs
	paf=paf
	Conv.pad!(pac.d, pac.dpad, pac.dlags[1], pac.dlags[2], pac.np2)
	mul!(pac.dfreq, pac.dfftp, pac.dpad)
	for i in eachindex(paf.window)
		paf.window[i]=complex(0.0,0.0)
	end

	nr=size(pac.dfreq,2)
	# stack the spectrum of data
	for j in 1:nr
		for i in eachindex(paf.window)
			paf.window[i] += (abs2(pac.dfreq[i,j]))
		end
	end

	normalize!(paf.window)
	paf.window = 10. * log10.(paf.window)

	# mute frequencies less than -40 dB
	for i in eachindex(paf.window)
		if(paf.window[i] ≤ -40)
			paf.window[i]=0.0
		else
			paf.window[i]=1.0
		end
	end
end

function apply_window_s!(s, pac, paf)
	Conv.pad!(s, pac.spad, pac.slags[1], pac.slags[2], pac.np2)
	mul!(pac.sfreq, pac.sfftp, pac.spad)
	for i in eachindex(pac.sfreq)
		pac.sfreq[i] *= paf.window[i]
	end
	mul!(pac.spad, pac.sifftp, pac.sfreq)
	Conv.truncate!(s, pac.spad, pac.slags[1], pac.slags[2], pac.np2)
end


function apply_window_g!(g, pac, paf)
	Conv.pad!(g, pac.gpad, pac.glags[1], pac.glags[2], pac.np2)
	mul!(pac.gfreq, pac.gfftp, pac.gpad)
	nr=size(pac.gfreq,2)
	for ir in 1:nr
		for i in size(pac.gfreq,1)
			pac.gfreq[i,ir] *= paf.window[i]
		end
	end
	mul!(pac.gpad, pac.gifftp, pac.gfreq)
	Conv.truncate!(g, pac.gpad, pac.glags[1], pac.glags[2], pac.np2)

end
=#
