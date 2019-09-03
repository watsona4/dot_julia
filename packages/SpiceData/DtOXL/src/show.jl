#SpiceData: Show functions
#-------------------------------------------------------------------------------

Base.show(io::IO, ::BigEndian) = print(io, "BigEndian")
Base.show(io::IO, ::LittleEndian) = print(io, "LittleEndian")

_showcompact(io::IO, ::SpiceFormat) = print(io, "Format:Unknown")
_showcompact(io::IO, ::Format_9601) = print(io, "SPICE:9601")
_showcompact(io::IO, ::Format_9602) = print(io, "CppSim:9602")
_showcompact(io::IO, ::Format_2001) = print(io, "SPICE:2001")
_showcompact(io::IO, ::Format_2013) = print(io, "SPICE:2013")

Base.show(io::IO, fmt::Format_Unknown) = _showcompact(io, fmt)

function Base.show(io::IO, fmt::SpiceFormat)
	_showcompact(io, fmt)
	print(io, " (x: $(xtype(fmt))[], y: $(ytype(fmt))[])")
end

function _show(io::IO, r::DataReader, compact::Bool = false)
	#Base (compact) information:
	print(io, DataReader, "(")
	print(io, basename(r.filepath))
	print(io, ", nsig=", length(r.signalnames))
	print(io, ", npts=", length(r.sweep))
	print(io, ", ")
	print(io, r.format)
	print(io, ")")
	if compact; return; end

	#Extended information:
	println(io)
	print(io, ">> (", r.endianness, ")")
	print(io, " sweep = '", r.sweepname, "'")
	println(io)
	tags = r.tags
	println(io, ">> ", tags.date, " (", tags.time, ")")
	println(io, ">> ", tags.id)
	println(io, ">> ", tags.comments)	
end

Base.show(io::IO, r::DataReader) = _show(io, r)
Base.show(io::IOContext, r::DataReader) = _show(io, r, haskey(io.dict, :compact))

#End
