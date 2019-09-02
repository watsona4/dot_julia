#LibPSF: Tools to read in values.
#-------------------------------------------------------------------------------


#==Main types
===============================================================================#

#PSF sweep accessors
#-------------------------------------------------------------------------------
#Used to extract data vectors:
mutable struct SweepValue{ID} #ID: identifies type of sweep (windowed/simple)
	vectorlist::Vector{Vector}
	id::Int
	name::String
	linktypeid::Int
	paramvalues::Vector
end
(::Type{SweepValue{ID}})() where ID = SweepValue{ID}(Vector[], 0, "", 0, [])

const SweepValueWindowed = SweepValue{:WND}
const SweepValueSimple = SweepValue{:SIMPLE}

#==Type identification functions
===============================================================================#
chunkid(::Type{T}) where T<:SweepValue = 16


#==Constructors
===============================================================================#
#Exception generators (TODO: Define exception types):
SimpleSweepNSError() = NotSuportedError("simple (non-windowed) sweep values")


#==Factories
===============================================================================#
#ValueSectionSweep::new_value
function new_value(section::ValueSectionSweep)
	if section.windowsize>0
		return SweepValueWindowed()
	else
		return SweepValueSimple()
	end
end

#DataTypeDef-based operations
#-------------------------------------------------------------------------------
#DataTypeDef::new_vector
new_vector(def::DataTypeDef) = psfdata_type(def)[] #Return empty array

#new_scalar(def::DataTypeDef): use psfdata_type(def), instead.

#DataTypeRef-based operations
#-------------------------------------------------------------------------------
#DataTypeRef::new_vector()
new_vector(ref::DataTypeRef, tsection::TypeSection) =
	new_vector(get_datatype(ref, tsection))


#==Helper functions
===============================================================================#
#GroupDef::fill_offsetmap
#offsetmap: offset starting points of each signal in a sweep group?
function fill_offsetmap(grp::GroupDef, offsetmap::TraceIDOffsetMap, typesection::TypeSection, windowsize::Int, startoffset::Int)
	offset = startoffset

	for child in grp.childlist #Loop through each signal in the group?
		offsetmap[child.id] = offset

		if windowsize != 0
			offset += windowsize
		else
			child_type = typeof(child)
			if child_type != DataTypeRef
				throw("Unexpected type: $child_type")
			end
			offset += datasize(child, typesection)
		end
	end

	return offset - startoffset
end

#ValueSectionSweep::_create_valueoffsetmap
function create_valueoffsetmap(r::DataReader, section::ValueSectionSweep)
	ref = nothing
	valueoffset = 0
	child_datasize = 0

	section.valuesize = 0
	section.ntraces = 0

	if section.windowsize > 0
		for child in r.traces.childlist
			child_type = typeof(child)
			if child_type <: GroupDef
				child_datasize = fill_offsetmap(child, section.offsetmap, r.types, section.windowsize, valueoffset)
			else
				throw(IncorrectChunk(chunkid(child_type)))
			end
		end

		section.valuesize += child_datasize;
      valueoffset += child_datasize;
	else
		for child in r.traces.childlist
			child_type = typeof(child)
			if child_type <: DataTypeRef
				ref = child::DataTypeRef
				datatypedef = get_datatype(ref, r.types)

	#In waveform families there is a data file that only contains sweep values.
	#In this case there are no trace values in the value section, yet there
	#is a trace in the trace section with the same datatypeid as in the sweep.
	#Data types of sweeps have a property called "key" which is set to "sweep" which
	#will be used to detect this problem to get a correct offset and child_datasize
				key = datatypedef.properties.prop["key"]
				if "sweep" == key; continue; end #Sikp over this element
				child_datasize = datatypedef._datasize
				section.offsetmap[ref.id] = valueoffset + 8;
			elseif child_type <: GroupDef
				child_datasize = fill_offsetmap(child, section.offsetmap, r.types, 0, valueoffset+8)
			else
				throw(IncorrectChunk(chunkid(child)))
			end

			section.valuesize += 8 + child_datasize;
			valueoffset += 8 + child_datasize;
		end
	end
	
end


#==Deserialize functions
===============================================================================#

#Ensure specialization of the vector copy (not sure how loop is optimized otherwise):
function deserialize_data(r::DataReader, v::Vector, rng::AbstractRange, ::Type{VALT}) where VALT
	for i in rng
		v[i] = read(r, VALT)
	end
end

#SweepValueWindowed::deserialize
#totaln: total number of sweep points
#filter: DataTypeRef[] of y-values?
deserialize(r::DataReader, value::SweepValueWindowed, totaln::Integer, windowoffset::Integer, filter::ChunkFilter) =
	deserialize(r, value, Int(totaln), Int(windowoffset), filter)
function deserialize(r::DataReader, value::SweepValueWindowed, totaln::Int, windowoffset::Int, filter::ChunkFilter)
	windowsize = Int(r.properties["PSF window size"])
	ntraces = Int(r.properties["PSF traces"])
	#totaln: total number of sweep points
	#ntraces: number of traces

	#x-value vector?
	paramtype = r.sweeps.childlist[1]::DataTypeRef #Throw exception if not right type

	if 0 == length(value.paramvalues) #Technically: if NULL
		value.paramvalues = new_vector(paramtype, r.types)
	end

	#Create data vectors
	resize!(value.vectorlist, 0)
	for chunk in filter
		trace = chunk::DataTypeRef #Validate type
		vec = new_vector(trace, r.types)
		resize!(vec, totaln)
		push!(value.vectorlist, vec)
	end

	i = 0
	while i < totaln
		deserialize_chunk(r, SweepValueWindowed)

		#Read number of points in this window (n)
		tmp = read(r, Int32)
		windowleft = tmp>>16 #Is this the rest of the number? Does it have another meaning?
		n = tmp & 0xFFFF #Number of data points in window (lower 32 bits)

		windowoffset += 4
		#Deserialize parameter values from file to parameter vector (paramvalues)
		pwinstart = length(value.paramvalues)
		resize!(value.paramvalues, pwinstart+n) #Continously grows???  Probably not: "value" should be destroyed after every call.
		VT = psfdata_type(paramtype, r.types)

		#x-value vector?
		deserialize_data(r, value.paramvalues, pwinstart .+ (1:n), VT)

		startpos = position(r.io) #Save start of trace values pointer in buffer (const char *valuebuf)
		valuesection = r.sweepvalues

		for j in 1:length(filter) #Also length of vectorlist
			typeref = filter[j]::DataTypeRef #Validate type
			VT = psfdata_type(typeref, r.types)
			pos = startpos + valuesection.offsetmap[typeref.id] + (windowsize-n*datasize(typeref, r.types))
			seek(r.io, pos)
			vec = value.vectorlist[j]

			deserialize_data(r, vec, i .+ (1:n), VT)
		end

		#Advance buffer pointer to end of trace values
		seek(r.io, startpos + ntraces * windowsize)
		i += n
	end

	return value
end

#SweepValueSimple::deserialize
#n: total number of sweep points
#filter: DataTypeRef[] of y-values?
deserialize(r::DataReader, value::SweepValueSimple, n::Integer, windowoffset::Integer, filter::ChunkFilter) =
	deserialize(r, value, Int(n), Int(windowoffset), filter)
function deserialize(r::DataReader, value::SweepValueSimple, n::Int, windowoffset::Int, filter::ChunkFilter)
	valuesection = r.sweepvalues

	for chunk in filter
		trace = chunk::DataTypeRef #Assert type
		vec = new_vector(trace, r.types)
		resize!(vec, n)
		push!(value.vectorlist, vec)
	end

	paramtype = r.sweeps.childlist[1]::DataTypeRef #Assert type

	if 0 == length(value.paramvalues) #Technically: if NULL
		value.paramvalues = new_vector(paramtype, r.types)
	end

	paramstartidx = length(value.paramvalues)
	resize!(value.paramvalues, paramstartidx+n)

	for i in 1:n
		deserialize_chunk(r, SweepValueSimple)
		paramtypeid = read(r, Int32)
		VT = psfdata_type(paramtype, r.types)
		if paramtypeid != paramtype.id
			throw("Read error: found $paramtypeid, expected: $(paramtype.id)")
		end

		#x-value vector?
		value.paramvalues[paramstartidx+i] = read(r, VT)

		startpos = position(r.io) #Save start of trace values pointer in buffer (const char *valuebuf)

		for k in 1:length(filter) #Also length of vectorlist
			trace = filter[k]::DataTypeRef #Validate type
			VT = psfdata_type(trace, r.types)
			pos = startpos + valuesection.offsetmap[trace.id]
			seek(r.io, pos)
			vec = value.vectorlist[k]
			vec[i] = read(r, VT)
		end
		pos = startpos + r.sweepvalues.valuesize
		seek(r.io, pos)
	end

	return value
end

#Last line
