#PSFWrite: Main section utilities
#-------------------------------------------------------------------------------


#==Other constructors
===============================================================================#
DataTypeInfo(::Type{Float64}, id::PSFWord, name::String) =
	DataTypeInfo(id, 0, TYPEID_FLOAT64, name, Property[], DataTypeInfo[])
function DataTypeInfo(::Type{Float64}, id::PSFWord, name::String, key::String, units::String)
	return DataTypeInfo(id, 0, TYPEID_FLOAT64, name,
		Property[Property("key", key), Property("units", units)], DataTypeInfo[]
	)
end

DataInfo(id::PSFWord, vec::VectorData, datatype::DataTypeInfo) =
	DataInfo(id, vec.id, datatype, Property[])


#==Defaults
===============================================================================#
#Default types:
const DTINFO_SWEEP  = DataTypeInfo(Float64, PSFWord(168068392), "sweep")
const DTINFO_NODE   = DataTypeInfo(Float64, PSFWord(168068448), "node", "node", "V")
const DTINFO_BRANCH = DataTypeInfo(Float64, PSFWord(168068504), "branch", "branch", "A")
const defaulttypelist = DataTypeInfo[DTINFO_SWEEP, DTINFO_NODE, DTINFO_BRANCH]

#Default sweep data info:
const DINFO_SWEEP = DataInfo(PSFWord(168068560), "time", DTINFO_SWEEP, [Property("units", "s")])


#==Helper functions
===============================================================================#
_next(idgen::IdGenerator) = (idgen.last += 0x50)


#==Write functions (Section info structures)
===============================================================================#

#Also updates info with current position (offset):
function writesectionid(io::IO, info::PrimarySectionInfo)
	info.offset = position(io)
	writeword(io, SECTIONID_PRIMARY)
	writeword(io, PSFWord(0)) #Skip over end position data
	return info
end
#Also updates info with current position (offset):
function writesectionid(io::IO, info::SectionInfo{T}) where T
	info.offset = position(io)
	writeword(io, T)
	writeword(io, PSFWord(0)) #Skip over end position data
	return info
end
function writeendpos(io::IO, info::AbstractSectionInfo)
	endpos = position(io) #Current position is end pos
	writeword_atpos(io, PSFWord(endpos), info.offset+sizeof(PSFWord))
end
function writesize(io::IO, info::IndexSectionInfo)
	endpos = position(io) #Current position is end pos
	startpos = info.offset+2*sizeof(PSFWord)
	_size = endpos - startpos
	writeword_atpos(io, PSFWord(_size), info.offset+sizeof(PSFWord))
end

function __write(io::IO, infolist::Vector{PrimarySectionInfo})
	szmax = typemax(PSFWord)
	for info in infolist
		if info.offset > szmax
			throw("This PSF format does not support files beyond: $szmax")
		end
		writeword(io, PSFWord(info.id))
		writeword(io, PSFWord(info.offset))
	end
end


#==Write functions (Header section)
===============================================================================#

function writeprop(io::IO, ds::PSFSweptDataset, wndsize::SizeT)
	ntraces = length(ds.vectorlist)
	bufsize = wndsize * (ntraces + 1) #+1 for sweep
	proplist = Property[
		Property("PSFversion", "1.1")
		Property("PSF style", 7)
		Property("PSF types", 1) #Float64
		Property("PSF sweeps", 1)
		Property("PSF sweep points", length(ds.sweep.v))
		Property("PSF sweep min", Float64(ds.sweep.v[1]))
		Property("PSF sweep max", Float64(ds.sweep.v[end]))
		Property("PSF groups", 1)
		Property("PSF traces", ntraces)
		Property("PSF buffer size", bufsize)
		Property("PSF window size", wndsize)
		Property("PsfTrailerFileNumber", 0)
		Property("PsfTrailerStart", 0)
		Property("PsfEndTableFileNumber", 0)
		Property("simulator", "Julia")
		Property("date", string(now()))
	]

	for prop in proplist
		__write(io, prop)
	end
end

function writeheader(w::PSFWriter, ds::PSFSweptDataset, wndsize::SizeT)
	info = writesectionid(w.io, PrimarySectionInfo(SECTIONID_HEADER))
	writeprop(w.io, ds, wndsize)
	writeendpos(w.io, info)
	return info
end


#==Write functions (Type section)
===============================================================================#

function __write(io::IO, info::DataTypeInfo)
	writeword(io, ELEMID_DATA)
	writeword(io, info.id)
	writeword(io, info.name)
	writeword(io, info.isvector)
	writeword(io, info.typeid)

	if info.typeid != TYPEID_STRUCT
		for subtype in info.subtypelist
			_write(io, subtype)
		end
	end

	for prop in info.proplist
		__write(io, prop)
	end
end

function __write(io::IO, v::Vector{DataTypeInfo})
	subinfo = writesectionid(io, SubSectionInfo())

	poslist = similar(v, PSFWord)
	for (i, info) in enumerate(v)
		poslist[i] = position(io)
		__write(io, info)
	end

	writeendpos(io, subinfo)
	indexinfo = writesectionid(io, IndexSectionInfo())

	#Write index to file:
	for (info, pos) in zip(v, poslist)
		writeword(io, info.id)
		writeword(io, pos)
	end
	writesize(io, indexinfo)
end

function writetypes(w::PSFWriter)
	info = writesectionid(w.io, PrimarySectionInfo(SECTIONID_TYPE))

	__write(w.io::IO, defaulttypelist)

	writeendpos(w.io, info)
	return info
end


#==Write functions (Sweep section)
===============================================================================#

function writesweeps(w::PSFWriter)
	info = writesectionid(w.io, PrimarySectionInfo(SECTIONID_SWEEP))

	__write(w.io::IO, DINFO_SWEEP)
	writeword(w.io, PSFWord(3)) #Sweep end??? Not sure why

	writeendpos(w.io, info)
	return info
end


#==Write functions (Trace section - Trace data info)
===============================================================================#

function __write(io::IO, grp::DataGroup)
	writeword(io, ELEMID_GROUP)
	writeword(io, grp.id)
	writeword(io, grp.name)
	writeword(io, PSFWord(length(grp.datalist)))

	poslist = similar(grp.datalist, PSFWord)
	for (i, data) in enumerate(grp.datalist)
		poslist[i] = position(io)
		__write(io, data)
	end

	return poslist
end

function __write(io::IO, v::Vector{DataGroup})
	subinfo = writesectionid(io, SubSectionInfo())

	if length(v) != 1
		throw("Only support 1 group")
	end

	grouppos = position(io)
	poslist = __write(io, v[1])

	writeendpos(io, subinfo)

	#Write DataGroup index:
	indexinfo = writesectionid(io, IndexSectionInfo())

	#Write trace index to file:
	for (info, pos) in zip(v[1].datalist, poslist)
		writeword(io, PSFWord(1481200216)) #Not sure what this is
		writeword(io, pos)
		writeword(io, v[1].id)
		writeword(io, typemax(PSFWord)) #Not sure why
	end

	#Write group index to file:
	writeword(io, PSFWord(1735552885)) #Not sure what this is
	writeword(io, PSFWord(grouppos))
	writeword(io, PSFWord(0))
	writeword(io, PSFWord(length(v[1].datalist)))

	writesize(io, indexinfo)
end

function writetraces(w::PSFWriter, ds::PSFSweptDataset)
	idgen = IdGenerator()
	info = writesectionid(w.io, PrimarySectionInfo(SECTIONID_TRACE))

	grp = DataGroup(PSFWord(169835016), "group")
	for vec in ds.vectorlist
		data = DataInfo(_next(idgen), vec, DTINFO_NODE)
		push!(grp.datalist, data)
	end
	__write(w.io, DataGroup[grp]) #Write array of groups (even if only 1)

	writeendpos(w.io, info)
	return info
end

#Last line
