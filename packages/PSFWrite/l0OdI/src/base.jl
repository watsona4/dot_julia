#PSFWrite: Base definitions
#-------------------------------------------------------------------------------

const PSFWord = UInt32
const SizeT = Int

#==Constants
===============================================================================#
const PSF_WORD0 = PSFWord(0x400) #First word in a PSF file
const PSF_STAMP = "Clarissa"

#Section identifiers
const SECTIONID_HEADER = PSFWord(0)
const SECTIONID_TYPE   = PSFWord(1)
const SECTIONID_SWEEP  = PSFWord(2)
const SECTIONID_TRACE  = PSFWord(3)
const SECTIONID_VALUE  = PSFWord(4)

const SECTIONID_VALUESEND  = PSFWord(0xF) #End of a value list section
const SECTIONID_PRIMARY    = PSFWord(0x15) #Primary section
const SECTIONID_SUBSECTION = PSFWord(0x16) #Does this just identify an indexed list??
const SECTIONID_INDEX      = PSFWord(0x13) #An actual (index, offset, ...) list

#Property type identifiers
const PROPTYPEID_STRING  = PSFWord(0x21)
const PROPTYPEID_INT32   = PSFWord(0x22)
const PROPTYPEID_FLOAT64 = PSFWord(0x23)

#Data type identifiers
const TYPEID_INT8           = PSFWord(0x1)
const TYPEID_STRING         = PSFWord(0x2)
const TYPEID_ARRAY          = PSFWord(0x3)
const TYPEID_INT32          = PSFWord(0x5)
const TYPEID_FLOAT64        = PSFWord(0xB)
const TYPEID_COMPLEXFLOAT64 = PSFWord(0xC)
const TYPEID_STRUCT         = PSFWord(0x10)

#PSF element identifiers:
const ELEMID_DATA     = PSFWord(0x10)
const ELEMID_GROUP    = PSFWord(0x11)
const ELEMID_ZEROPAD  = PSFWord(0x14)


#==Main Types
===============================================================================#
const Integer32 = Union{Int32,UInt32}
const Integer8 = Union{Int8,UInt8}

mutable struct Property
	key::String
	value::Any
end

mutable struct DataTypeInfo
	id::PSFWord #Unique id? Maybe be a hash key?
	isvector::PSFWord #Not sure what this is
	typeid::PSFWord #TYPEID_*
#	_size::PSFWord #Size: not written
	name::String
	proplist::Vector{Property}
	subtypelist::Vector{DataTypeInfo} #A struct is made up of subtypes
end

mutable struct DataInfo
	id::PSFWord #Unique id? Maybe be a hash key?
	name::String
	datatype::DataTypeInfo
	proplist::Vector{Property}
end

mutable struct DataGroup
	id::PSFWord
	name::String
	datalist::Vector{DataInfo}
end
DataGroup(id::PSFWord, name::String) = DataGroup(id, name, DataInfo[])

#Sections
#-------------------------------------------------------------------------------
abstract type AbstractSectionInfo end

mutable struct SectionInfo{ID} <: AbstractSectionInfo
	offset::SizeT
end
(::Type{SectionInfo{ID}})() where ID = SectionInfo{ID}(0)

const SubSectionInfo = SectionInfo{SECTIONID_SUBSECTION}

#Maybe better not to make this a "Section"?:
const IndexSectionInfo = SectionInfo{SECTIONID_INDEX}

mutable struct PrimarySectionInfo <: AbstractSectionInfo
	id::PSFWord
	offset::SizeT
end
PrimarySectionInfo(id::PSFWord) = PrimarySectionInfo(id, 0)

#High-level writer
#-------------------------------------------------------------------------------
#Generates unique IDs
mutable struct IdGenerator
	last::PSFWord
end
IdGenerator() = IdGenerator(168068640)

mutable struct VectorData
	id::String
	v::Vector
end

mutable struct PSFSweptDataset
	sweep::VectorData
	vectorlist::Vector{VectorData}
end
PSFSweptDataset(sweepvec::VectorData) =
	PSFSweptDataset(sweepvec, VectorData[])

mutable struct PSFWriter
	io::IOStream
end


#==Other constructors
===============================================================================#


#==Type identification functions
===============================================================================#
psfpropertyid(::Type{String}) = PROPTYPEID_STRING
psfpropertyid(::Type{T}) where T<:Integer32 = PROPTYPEID_INT32
psfpropertyid(::Type{Float64}) = PROPTYPEID_FLOAT64


#==Basic functions
===============================================================================#
poweroftwo(v::T) where T<:Integer = v == (T(1)<<Int(log2(v)))

#Compute # of bytes remaining within word boundary after writing given amount of bytes:
@assert(poweroftwo(sizeof(PSFWord)), "Algorithms expect sizeof(PSFWord) to be a power of two")
bytesremaining(nbytes::Integer, ::Type{PSFWord}) = (sizeof(PSFWord)-Int(nbytes)) & (sizeof(PSFWord)-1)


#==Write functions (basic types)
===============================================================================#
@assert(PSFWord<:Integer32, "Incorrect assumption: PSFWord not 32-bits.")

#Write data, respecting word boundaries:
writeword(io::IO, v::Integer8) = write(io, hton(PSFWord(reinterpret(UInt8, v))))
writeword(io::IO, v::Integer32) = write(io, hton(v))
writeword(io::IO, v::Float64) = write(io, hton(v))
writeword(io::IO, v::Complex{Float64}) = write(io, hton(real(v)), hton(imag(v)))

#Write data at a given position (respecting word boundaries):
function writeword_atpos(io::IO, v::Integer32, pos::SizeT; restorepos=true)
	curpos = position(io) #current position is end pos
	seek(io, pos)
	writeword(io, v)
	if restorepos; seek(io, curpos); end
end

#Zero-out remaining bytes to a word boundary (after writing nbytes):
function zeroremaining(io::IO, nbytes::Integer, ::Type{WORDT}) where WORDT
	rmg = bytesremaining(nbytes, WORDT)
	for i in 1:rmg 
		write(io, UInt8(0))
	end
end

function writeword(io::IO, v::Vector{T}) where T<:Integer8
	write(io, v)
	zeroremaining(io, length(v), PSFWord)
end

function writeword(io::IO, s::String)
	strlen = length(s)
	writeword(io, PSFWord(strlen))
	writeword(io, convert(Vector{UInt8}, codeunits(s)))
end

#==Write functions (Data types)
===============================================================================#
function __write(io::IO, prop::Property)
	#Limit value types to one of supported values:
	valtype = typeof(prop.value)
	if valtype <: Integer
		valtype = Int32
	elseif valtype <: Real
		valtype = Float64
	end

	writeword(io, psfpropertyid(valtype))
	writeword(io, prop.key)
	writeword(io, valtype(prop.value))
end

function __write(io::IO, info::DataInfo)
	writeword(io, ELEMID_DATA)
	writeword(io, info.id)
	writeword(io, info.name)
	writeword(io, info.datatype.id)
	for prop in info.proplist
		__write(io, prop)
	end
end

#Last line
