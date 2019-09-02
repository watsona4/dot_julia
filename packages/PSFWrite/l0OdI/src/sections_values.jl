#PSFWrite: "Values" section utilities
#-------------------------------------------------------------------------------


#==Other constructors
===============================================================================#


#==Helper functions
===============================================================================#
function validatedataset(ds::PSFSweptDataset)
	sweeplen = length(ds.sweep.v)
	for vec in ds.vectorlist
		if length(vec.v) != sweeplen
			throw("Vector length does not match sweep: $(vec.id)")
		end
	end
end


#==Write functions
===============================================================================#
function writebyte(io::IO, val::UInt8, nbytes::SizeT)
	for i in 1:nbytes
		write(io, val)
	end
end
function writezeropad(io::IO, boundary::SizeT)
	writeword(io, ELEMID_ZEROPAD)
	padstart = position(io) + sizeof(PSFWord) #Reserve space for pad length
	#Want to align values wo window boundary:
	padend = div(padstart+(boundary-1), boundary) * boundary
	padlen = padend - padstart

	writeword(io, PSFWord(padlen))
	writebyte(io, UInt8(0), padlen)
end


function writevalues(w::PSFWriter, ds::PSFSweptDataset, wndsize::SizeT)
#=TODO:
Not convinced values are written at correct location.
Might need correcting
=#
	info = writesectionid(w.io, PrimarySectionInfo(SECTIONID_VALUE))
	validatedataset(ds)
	sweeplen = length(ds.sweep.v)
	datasize = sizeof(Float64)

	writezeropad(w.io, wndsize)
	reservedsize = 2*sizeof(PSFWord) #Reserve space for ID & # of values in window

	#Num values per window (only supports Float64 vectors):
	maxvalperwnd = div(wndsize-reservedsize, datasize)

	npasses = div(sweeplen+(maxvalperwnd-1), maxvalperwnd)
	for ipass in 1:npasses
		offset = (ipass-1)*maxvalperwnd
		nval = min(maxvalperwnd, sweeplen-offset)
		npad = wndsize - reservedsize - nval*datasize

		writeword(w.io, ELEMID_DATA)
		writeword(w.io, PSFWord(nval))

		for i in offset .+ (1:nval)
			writeword(w.io, Float64(ds.sweep.v[i]))
		end
		writebyte(w.io, UInt8(0), npad)

		for vec in ds.vectorlist
			writebyte(w.io, UInt8(0), reservedsize)
			for i in offset .+ (1:nval)
				writeword(w.io, Float64(vec.v[i]))
			end
			writebyte(w.io, UInt8(0), npad)
		end
	end

	writeendpos(w.io, info)
	return info
end


#Last line
