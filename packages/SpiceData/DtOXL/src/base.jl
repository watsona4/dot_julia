#SpiceData: Base types & core functions
#-------------------------------------------------------------------------------


#==Aliases
===============================================================================#
const DataWord = UInt32


#==Constants
===============================================================================#
const SIGNAME_BUFSIZE = 256 #Maximum supported length

const WRITEBLOCK_SYNCWORD = DataWord(0x4)
const WRITEBLOCK_HEADERSIZE = 4*sizeof(DataWord)

#TODO: Not convinced this code is really "block type"... or if ids match their meaning.
const BLOCKTYPEID_HEADER = DataWord(0x70)
const BLOCKTYPEID_DATA = DataWord(0x80)

const DATATYPEID_VOLTAGE = 1
const DATATYPEID_CURRENT = 8

const SWEEPDATA_LASTPOINT = 1e30 #Can detect end of data with this.


#==Main Types
===============================================================================#
abstract type Endianness end #Of data file
struct BigEndian <: Endianness; end
struct LittleEndian <: Endianness; end
const NetworkEndianness = BigEndian #Informative only
#=Comment:
Apparently SPICE files used to use network endianness (big-endian), but are now
little-endian.
=#

abstract type SpiceFormat end
struct Format_Unknown <: SpiceFormat; end
struct Format_9601 <: SpiceFormat; end #x: 32-bit floats, y: 32-bit floats
struct Format_9602 <: SpiceFormat; end #x: 64-bit floats, y: 64-bit floats
struct Format_2001 <: SpiceFormat; end #x: 64-bit floats, y: 64-bit floats
struct Format_2013 <: SpiceFormat; end #x: 64-bit floats, y: 32-bit floats
#=Comment:
I believe 9602 is a non-standard format used by CppSim.
=#

struct BlockHeader
	typeid::DataWord #TODO: is this really type id?
	_size::DataWord #Number of bits in current block
end

mutable struct BlockReader{T<:Endianness}
	io::IO
	header::BlockHeader
	endpos::Int
end
#NOTE: Parameterized so we can specialize (dispatch) on endianness.

#Convenience:
Endianness(::BlockReader{E}) where E<:Endianness = E

#TODO: Not sure if the SpiceTags are named correctly:
mutable struct SpiceTags
	id::String
	date::String
	time::String
	comments::String
end
SpiceTags() = SpiceTags("", "", "", "")

#SPICE file reader: Main object
#-------------------------------------------------------------------------------
mutable struct DataReader
	io::IOStream
	filepath::String #Informative only
	format::SpiceFormat
	sweepname::String
	signalnames::Vector{String}
	sweep::Vector
	tags::SpiceTags
	datastart::Int
	rowsize::Int
	endianness::Endianness
end


#==Exceptions
===============================================================================#
function corruptword_exception(io::IO, w::DataWord, expected::DataWord)
	pos = position(io) - sizeof(DataWord)
	pos = hex(pos)
	w = hex(w)
	expected = hex(expected)
	return "Corrupt word 0x$w @ 0x$pos (expected 0x$expected)"
end

function stringboundary_exception(io::IO, )
	hpos = hex(position(io))
	return "Reading string across block boundary: 0x$hpos"
end


#==Helper Functions
===============================================================================#

printable(v::String) = isprint(v) ? v : ""

#Debug: show block header info
function _show(io::IO, hdr::BlockHeader, pos::Int)
	print(io, "Block: 0x", hex(WRITEBLOCK_SYNCWORD))
	print(io, " 0x", hex(hdr.typeid))
	print(io, " 0x", hex(WRITEBLOCK_SYNCWORD))
	print(io, " 0x", hex(hdr._size))
	print(io, " (start 0x", hex(pos), ")")
	println(io)
end

#-------------------------------------------------------------------------------
xtype(::Format_9601) = Float32
ytype(::Format_9601) = Float32

xtype(::Format_9602) = Float64
ytype(::Format_9602) = Float64

xtype(::Format_2001) = Float64
ytype(::Format_2001) = Float64

xtype(::Format_2013) = Float64
ytype(::Format_2013) = Float32

#-------------------------------------------------------------------------------
_reorder(v::T, ::BigEndian) where T = ntoh(v)
_reorder(v::T, ::LittleEndian) where T = ltoh(v)

#IO reads
#-------------------------------------------------------------------------------
_read(io::IO, ::Type{T}, endianness::Endianness) where T<:Real =
	_reorder(read(io, T), endianness)

#Read in a WRITEBLOCK_SYNCWORD & validate:
function readsyncword(io::IO, endianness::Endianness)
	w = _read(io, DataWord, endianness)
	if w != WRITEBLOCK_SYNCWORD
		throw(corruptword_exception(io, w, WRITEBLOCK_SYNCWORD))
	end
end

#Read in a block header:
function _read(io::IO, ::Type{BlockHeader}, endianness::Endianness)
	readsyncword(io, endianness)
	typeid = _read(io, DataWord, endianness)
	readsyncword(io, endianness)
	_size = _read(io, DataWord, endianness)
	return BlockHeader(typeid, _size)
end

#Block reader
#-------------------------------------------------------------------------------
bytesleft(r::BlockReader) = (r.endpos - position(r.io))
canread(r::BlockReader, nbytes::Int) = bytesleft(r) >= nbytes

function nextblock(r::BlockReader{E}) where E
	seek(r.io, r.endpos)
	sz = _read(r.io, DataWord, E())
	if sz != r.header._size
		hpos = hex(position(r.io) - 1)
		throw("Inconsistent block size @ 0x$hpos.")
	end
	r.header = _read(r.io, BlockHeader, E())
	r.endpos = position(r.io) + r.header._size
	return r
end

function _skip(r::BlockReader, offset::Int)
	while offset > 0
		rmg = offset - bytesleft(r)
		if rmg > 0
			nextblock(r)
			offset = rmg
		else
			return skip(r.io, offset)
		end
	end
end

function _read(r::BlockReader{E}, ::Type{T}) where {E, T<:Number}
	#NOTE: don't check if bytesleft<0... checked by reading BlockHeader
	if bytesleft(r) < 1
		nextblock(r)
	end

	if !canread(r, sizeof(T))
		hpos = hex(position(r.io))
		throw("Cannot read $T @ 0x$hpos")
	end

	return _read(r.io, T, E())
end

#Read in fixed-length string:
function _read(r::BlockReader, ::Type{String}, nchars::Int)
	if !canread(r, nchars)
		throw(stringboundary_exception(r.io))
	end
	buf = Array{UInt8}(undef, nchars)
	readbytes!(r.io, buf)
	return String(buf)
end

#Read in space-delimited string:
function readsigname(r::BlockReader)
	DELIM = UInt8(' ') #WANTCONST
	buf = Array{UInt8}(undef, SIGNAME_BUFSIZE)

	#TODO: improve test?
	isdelim(v::UInt8) = (v != DELIM)

	lastchar = DELIM
	while DELIM == lastchar
		lastchar = _read(r, UInt8)
	end

	if !isdelim(lastchar)
		hpos = hex(position(r.io)-1)
		throw("Invalid string @ 0x$hpos")
	end

	i = 1
	while isdelim(lastchar)
		buf[i] = lastchar
		lastchar = _read(r, UInt8)
		i+=1
		if i > SIGNAME_BUFSIZE
			throw("Insufficient buffer size: 'SIGNAME_BUFSIZE'")
		end
	end

	buf[i] = 0
	return unsafe_string(pointer(buf))
end


#==Constructors
===============================================================================#
#"Construct" a BlockReader, by reading a header from IO:
function BlockReader(io::IO, endianness::Endianness; start::Int=0)
	seek(io, start)
	hdr = _read(io, BlockHeader, endianness)
	endpos = position(io) + hdr._size
	return BlockReader{typeof(endianness)}(io, hdr, endpos)
end


#==Main functions
===============================================================================#
#Detect endianness from first word:
function _read(io::IO, ::Type{Endianness})
	w = read(io, DataWord)
	for endianness in [LittleEndian(), BigEndian()]
		if WRITEBLOCK_SYNCWORD == _reorder(w, endianness)
			return endianness
		end
	end
	throw(corruptword_exception(io, w, WRITEBLOCK_SYNCWORD))
end

#Read in SPICE data file format:
function _read(r::BlockReader, ::Type{SpiceFormat})
	versiontxt = strip(_read(r, String, 8))

	try
		version = parse(Int, versiontxt)
		if 9601 == version
			return Format_9601()
		elseif 9602 == version
			return Format_9602()
		elseif 2001 == version
			return Format_2001()
		elseif 2013 == version
			return Format_2013()
		end
	catch
	end

	versiontxt = printable(versiontxt)
	throw("SPICE data format not recognized: '$versiontxt'")
end

#Read in signal names:
function readnames(r::BlockReader, datacolumns::Int)
	for i in 1:datacolumns
		sigtype = _read(r, String, 8)
		try
			parse(Int, sigtype)
		catch
			hpos = hex(position(r.io) - 8)
			sigtype = printable(sigtype)
			throw("Non-numerical signal type '$sigtype' @ 0x$hpos")
		end
	end

	sweepname = readsigname(r)
	nsigs = datacolumns - 1

	signalnames = Array{String}(undef, nsigs)
	for i in 1:length(signalnames)
		signalnames[i] = readsigname(r)
	end

	return (sweepname, signalnames)
end

#Read in signal data to vector d.
function readsignal!(r::BlockReader, d::Vector{T}, offset::Int, rowsize::Int) where T
	rowskip = rowsize - sizeof(T)
	_skip(r, offset)
	lastrowcomplete = false
	npoints = 0
	lastpos = 0

	try
		while npoints <= length(d)
			val = _read(r, T)
			npoints += 1
			d[npoints] = val
			lastrowcomplete = false
#lastpos=position(r.io)
			_skip(r, rowskip)
			lastrowcomplete = true
		end
	catch
	end

	#When reading main sweep (offset == 0):
	#Get rid of last value if last row is not completely written:
	if 0 == offset && !lastrowcomplete
#hpos = hex(lastpos); chpos = hex(position(r.io))
#throw("INCOMPLETE DATASET: lastpos @0x$hpos (curpos @0x$chpos)")
		npoints = max(0, npoints-1)
	end

	return resize!(d, npoints)
end

#Read in main sweep vector:
function readsweep(r::BlockReader, fmt::SpiceFormat, rowsize::Int)
	#Compute estimated signal length:
	curpos = position(r.io)
	sz = filesize(r.io)
	estimatedlen = div(sz - curpos, rowsize)

	data = Array{xtype(fmt)}(undef, estimatedlen)
	return readsignal!(r, data, 0, rowsize)
end

#Read in signal by number:
function readsignal(r::DataReader, signum::Int)
	nsigs = length(r.signalnames)
	if signum < 1 || signum > nsigs
		throw("Invalid signal number: $signum ∉ [1, $nsigs].")
	end
	blkreader = BlockReader(r.io, r.endianness, start=r.datastart)
	_xtype = xtype(r.format); _ytype = ytype(r.format)
	offset = sizeof(_xtype) + (signum-1) * sizeof(_ytype)
	data = Array{_ytype}(undef, length(r.sweep))
	return readsignal!(blkreader, data, offset, r.rowsize)
end

#Read in a SPICE file from path:
function _open(filepath::String)
	io = open(filepath, "r")
	endianness = _read(io, Endianness)
	blkreader = BlockReader(io, endianness, start=0)

	#Read in signal counts:
	count1 = _read(blkreader, String, 4)
	#What are other counts for? Are they counts?
	count2 = _read(blkreader, String, 4)
	count3 = _read(blkreader, String, 4)
	count4 = _read(blkreader, String, 4)

	try
		count1 = parse(Int, count1)
		count2 = parse(Int, count2)
	catch
		throw("Invalid signal count.")
	end
	datacolumns = Int(count1)+Int(count2)

	#Read in file format:
	format = _read(blkreader, SpiceFormat)

	#Read in "tags":
	header = SpiceTags(
		strip(_read(blkreader, String, 4*16)), #id
		strip(_read(blkreader, String, 16)), #date
		strip(_read(blkreader, String, 8)), #time
		strip(_read(blkreader, String, 4*16+8)) #comments
	)

	#Read in signal names:
	_skip(blkreader, 5*16) #Why? What is here?
	sweepname, signalnames = readnames(blkreader, datacolumns)

	#Compute row size:
	nsigs = length(signalnames)
	_xtype = xtype(format); _ytype = ytype(format)
	rowsize = sizeof(_xtype) + nsigs*sizeof(_ytype)

	#Move to start of first data block:
	nextblock(blkreader)
	datastart = position(blkreader.io) - WRITEBLOCK_HEADERSIZE

	sweep = readsweep(blkreader, format, rowsize)

	return DataReader(io, filepath, format,
		sweepname, signalnames, sweep,
		header, datastart, rowsize, endianness
	)
end


#==Higher-level interface
===============================================================================#
#_open(filepath::String)
Base.names(r::DataReader) = r.signalnames
Base.read(r::DataReader, signum::Int) = readsignal(r, signum)
function Base.read(r::DataReader, signame::String)
	signum = findfirst(isequal(signame), r.signalnames)
	if nothing == signum
		throw("Signal not found: $signame.")
	end
	return readsignal(r, signum)
end
Base.close(r::DataReader) = close(r.io)

#Last line
