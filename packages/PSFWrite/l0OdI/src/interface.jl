#PSFWrite: High-level interface
#-------------------------------------------------------------------------------

#==Generator functions
===============================================================================#
#Generate a data block to be written:
#Un-exported (high likelyhood of collisions)
dataset(sweep::Vector, sweepid::String) =
	PSFSweptDataset(VectorData(sweepid, sweep))

Base.push!(ds::PSFSweptDataset, vec::Vector, id::String) =
	push!(ds.vectorlist, VectorData(id, vec))


#==Write functions
===============================================================================#

function Base.write(w::PSFWriter, ds::PSFSweptDataset)
	wndsize = SizeT(0x1000) #WANTCONST
	infolist = PrimarySectionInfo[]

	seekend(w.io)
	if position(w.io) != 0
		throw("PSFWriter can only write to empty files.")
	end

	writeword(w.io, PSF_WORD0)

	push!(infolist, writeheader(w, ds, wndsize))
	push!(infolist, writetypes(w))
	push!(infolist, writesweeps(w))
	push!(infolist, writetraces(w, ds))
	push!(infolist, writevalues(w, ds, wndsize))

	#Write trailing info:
	trailinginfostart = position(w.io)
	__write(w.io, infolist) #Write section info
	writeword(w.io, convert(Vector{UInt8}, codeunits(PSF_STAMP)))
	writeword(w.io, PSFWord(trailinginfostart))
end


#==Open/close functions
===============================================================================#
function _open(filepath::String)
	io = open(filepath, "w")
	return PSFWriter(io)
end

function _open(fn::Function, filepath::String)
	writer = _open(filepath)
	try
		fn(writer)
	finally
		close(writer)
	end
end

Base.close(w::PSFWriter) = close(w.io)

#Last line
