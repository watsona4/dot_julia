# define tgrid while storing cross-correlations
xcorr_range(tgrid)=range(-1*abs(tgrid[end]-tgrid[1]),stop=abs(tgrid[end]-tgrid[1]),length=2*length(tgrid)-1)

function save(pa::Param, folder; tgridg=nothing, tgrid=nothing, tgrids=nothing)
	!(isdir(folder)) && error("invalid directory")

	save(pa.pfibd,folder,tgridg=tgridg, tgrid=tgrid,tgrids=tgrids)
	save(pa.pfpr,folder,tgridg=tgridg)
	#save(pa.lsbd,tgridg=tgridg, tgrid=tgrid)
end

"""
Save BD
* `tgridg` : 1D grid for Green's functions
* `tgrid` : 1D grid for the data
"""
function save(pa::BD, folder; tgridg=nothing, tgrid=nothing)
	!(isdir(folder)) && error("invalid directory")


	save(pa.om, folder, tgridg=tgridg, tgrid=tgrid)
	save(pa.optm, folder, tgridg=tgridg, tgrid=tgrid)
	savex(pa.optm, folder, tgridg=tgridg, tgrid=tgrid)

	# finally save err
	err!(pa) # compute err in cal 
	file=joinpath(folder, "err.csv")
	CSV.write(file, pa.err)
end


"""
Save IBD
"""
function save(pa::IBD, folder; tgridg=nothing, tgrid=nothing, tgrids=nothing)
	!(isdir(folder)) && error("invalid directory")

	@info "saving results of fibd"
	(tgridg===nothing) && (tgridg = range(0.0, stop=(pa.om.ntg-1)*1.0, length=pa.om.ntg))
	(tgrid===nothing) && (tgrid = range(0.0, stop=(pa.om.nt-1)*1.0, length=pa.om.nt))
	(tgrids===nothing) && (tgrids = range(0.0, stop=(pa.om.nts-1)*1.0, length=pa.om.nts))

	save(pa.om, folder, tgridg=tgridg, tgrid=tgrid, tgrids=tgrids)
	save(pa.optm, folder, tgridg=xcorr_range(tgridg), tgrid=xcorr_range(tgrid))

	# finally save err
	err!(pa) # compute err in cal 
	file=joinpath(folder, "err.csv")
	CSV.write(file, pa.err)
end


function save(pa::FPR, folder; tgridg=nothing, gobs=nothing)
	!(isdir(folder)) && error("invalid directory")

	@info "saving results of fpr"
	ntg=size(pa.g,1)
	nr=size(pa.g,2)
	(tgridg===nothing) && (tgridg = range(0.0, stop=(ntg-1)*1.0, length=ntg))

	# save observed vs modelled data
	save_cross(hcat(pa.p_misfit_xcorr.cy...),hcat(pa.p_misfit_xcorr.pxcorr.cg...), 
	    "dfpr", folder)

	file=joinpath(folder, "gfpr.csv")
	CSV.write(file,DataFrame(hcat(tgridg, pa.g)))
	
	file=joinpath(folder, "imgfpr.csv")
	CSV.write(file,DataFrame(hcat(repeat(tgridg,outer=nr),repeat(1:nr,inner=ntg),vec(pa.g))),)

	if(!(gobs===nothing))
		file=joinpath(folder, "gfprobs.csv")
		CSV.write(file,DataFrame(hcat(tgridg, gobs)))

		file=joinpath(folder, "imgfprobs.csv")
		CSV.write(file,DataFrame(hcat(repeat(tgridg,outer=nr),repeat(1:nr,inner=ntg),vec(gobs))),)
	end

end



function save(pa::ObsModel, folder; tgridg=nothing, tgrid=nothing, tgrids=nothing)
	!(isdir(folder)) && error("invalid directory")


	(tgridg===nothing) && (tgridg = range(0.0, stop=(pa.ntg-1)*1.0, length=pa.ntg))
	(tgrid===nothing) && (tgrid = range(0.0, stop=(pa.nt-1)*1.0, length=pa.nt))
	(tgrids===nothing) && (tgrids = range(0.0, stop=(pa.nts-1)*1.0, length=pa.nts))

	# save original g
	file=joinpath(folder, "gobs.csv")
	CSV.write(file,DataFrame(hcat(tgridg, pa.g)))

	# save g for imagesc plots in TikZ
	file=joinpath(folder, "imgobs.csv")
	CSV.write(file,DataFrame(hcat(repeat(tgridg,outer=pa.nr),repeat(1:pa.nr,inner=pa.ntg),vec(pa.g))),)

	# save original s
	file=joinpath(folder, "sobs.csv")
	CSV.write(file,DataFrame(hcat(tgrids,pa.s)))

	# save data
	file=joinpath(folder, "dobs.csv")
	CSV.write(file,DataFrame(hcat(tgrid, pa.d)))
end

function save(pa::OptimModel, folder; tgridg=nothing, tgrid=nothing,tgrids=nothing)
	!(isdir(folder)) && error("invalid directory")

	(tgridg===nothing) && (tgridg = range(0.0, stop=(pa.ntg-1)*1.0, length=pa.ntg))
	(tgrids===nothing) && (tgrids = range(0.0, stop=(pa.nts-1)*1.0, length=pa.nts))
	(tgrid===nothing) && (tgrid = range(0.0, stop=(pa.nt-1)*1.0, length=pa.nt))

	save_obscal(pa.obs.g, pa.cal.g, tgridg, "goptm", folder)
	save_obscal(pa.obs.d, pa.cal.d, tgrid, "doptm", folder)
	save_obscal(pa.obs.s, pa.cal.s, tgrids, "soptm", folder)

	save_cross(pa.obs.d,pa.cal.d, "doptm", folder)
	save_cross(pa.obs.g,pa.cal.g, "goptm", folder)
	save_cross(pa.obs.s,pa.cal.s, "soptm", folder)
end

	
function savex(pa::OptimModel, folder; tgridg=nothing, tgrid=nothing)
	!(isdir(folder)) && error("invalid directory")

	(tgridg===nothing) && (tgridg = range(0.0, stop=(pa.ntg-1)*1.0, length=pa.ntg))
	(tgrid===nothing) && (tgrid = range(0.0, stop=(pa.nt-1)*1.0, length=pa.nt))

	xtgridg=xcorr_range(tgridg); 
	xtgrid=xcorr_range(tgrid)

	xgobs=Conv.xcorr(pa.obs.g)[1]
	xgcal=Conv.xcorr(pa.cal.g)[1]

	save_obscal(xgobs, xgcal, xtgridg, "xg", folder)

	# compute cross-correlations without blind Decon
	xdobs=Conv.xcorr(pa.obs.d,Conv.P_xcorr(pa.nt, pa.nr, cglags=[pa.ntg-1, pa.ntg-1]))[1]
	xdcal=Conv.xcorr(pa.cal.d,Conv.P_xcorr(pa.nt, pa.nr, cglags=[pa.ntg-1, pa.ntg-1]))[1]
	xsobs=(Conv.xcorr(pa.obs.s,Conv.P_xcorr(pa.nt, 1, cglags=[pa.ntg-1, pa.ntg-1]))[1])
	xscal=(Conv.xcorr(pa.cal.s,Conv.P_xcorr(pa.nt, 1, cglags=[pa.ntg-1, pa.ntg-1]))[1])

	save_obscal(xdobs, xdcal, xtgridg, "xdat", folder)
	save_obscal(xsobs, xscal, xtgridg, "xs", folder)


	save_cross(xdobs,xdcal, "xdat", folder)
	save_cross(xsobs,xscal, "xs", folder)
	save_cross(xgobs,xgcal, "xg", folder)
end



function save_cross(a,b, name, folder; num=1000)
	(length(a) ≠ length(b)) && error("size mismatch")

	# x plots of data
	nd=length(b);
	fact=(nd>num) ? round(Int,nd/num) : 1
	b=b[1:fact:nd]
	a=a[1:fact:nd]
	datmat=hcat(vec(b), vec(a))
	rmul!(datmat, inv(maximum(abs, datmat)))

	file=joinpath(folder, string(name, "cross.csv"))
	CSV.write(file,DataFrame( datmat))
end



function save_obscal(a,b, x, name, folder)
	(size(a) ≠ size(b)) && error("size mismatch")
	nr=size(a,2)
	nt=size(a,1)

	# save obs
	file=joinpath(folder, string(name,"obs.csv"))
	CSV.write(file,DataFrame(hcat(x, a)))
	# save cal
	file=joinpath(folder, string(name, "cal.csv"))
	CSV.write(file,DataFrame(hcat(x, b)))


	# save g for imagesc plots in TikZ
	file=joinpath(folder, string("im", name, "obs.csv"))
	CSV.write(file,DataFrame(hcat(repeat(x,outer=nr),repeat(1:nr,inner=nt),vec(a))))

	file=joinpath(folder, string("im", name, "cal.csv"))
	CSV.write(file,DataFrame(hcat(repeat(x,outer=nr),repeat(1:nr,inner=nt),vec(b))))

end

