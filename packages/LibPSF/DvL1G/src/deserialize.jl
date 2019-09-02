#LibPSF: Main deserialize functions
#-------------------------------------------------------------------------------

#==Deserialize functions
===============================================================================#

#DataTypeDef::deserialize_data (not implemented)
#Originally acted on address of a data element.
#Instead, implemented here as simple read(reader, DataType) function.

#Deserialize basic bits types
#-------------------------------------------------------------------------------
#TODO: remove this layer, and call read directly??

#PSFInt8Scalar::deserialize(const char *buf)
deserialize(r::DataReader, ::Type{Int8}) = read(r, Int8)
#PSFInt32Scalar::deserialize(const char *buf)
deserialize(r::DataReader, ::Type{Int32}) = read(r, Int32)
#PSFDoubleScalar::deserialize(const char *buf)
deserialize(r::DataReader, ::Type{Float64}) = read(r, Float64)
#PSFComplexDoubleScalar::deserialize(const char *buf)
#deserialize(r::DataReader, ::Type{Complex{Float64}}) = read(r, Float64) #???
#This is probably not used

#PSFStringScalar::deserialize
function deserialize(r::DataReader, ::Type{String})
	len = read(r, Int32)
	data = Array{UInt8}(undef, (len,))
	read!(r.io, data)
	value = String(data)

	#Align to 32-bit boundary:
	rmg = (4-len) & 3
	data = Array{UInt8}(undef, (rmg,)) #Dummy buffer
	read!(r.io, data)
	return value
end

#PropertyBlock::deserialize
function deserialize(r::DataReader, ::Type{PropertyBlock})
	result = PropertyBlock()
	while true
		curpos = position(r.io)
		chunktype = read(r, Int32)
		seek(r.io, curpos) #Must be re-read

		if ischunk(chunktype, Property)
			prop = Property()
			deserialize(r, prop)
			push!(result.prop, prop.name => prop.value)
		else
			break
		end
	end
	return result
end

#Chunk::deserialize
function deserialize_chunk(r::DataReader, T::Type)
	testtype = read(r, UInt32)
	cid = chunkid(T)

	if cid != -1 && testtype != cid
		throw(IncorrectChunk(testtype))
	end
	return true #This function really ensures we have expected chunk
end

#ZeroPad::deserialize
function deserialize(r::DataReader, ::Type{ZeroPad})
	deserialize_chunk(r, ZeroPad)
	_size = read(r, UInt32)
	curpos = position(r.io)
	seek(r.io, curpos+_size)
end

#Property::deserialize
function deserialize(r::DataReader, child::Property)
	chunktype = read(r, Int32)
   if(!ischunk(chunktype, Property))
		throw(IncorrectChunk(chunktype))
	end

	child.name = deserialize(r, String)

	ptype = propertytype(chunktype)
	child.value = deserialize(r, ptype)
	return child
end

#Index::deserialize
#Does not seem to do anything.
function deserialize(r::DataReader, ::Type{Index})
	deserialize_chunk(r, Index)
	_size = read(r, UInt32)

	nvals = div(_size, 4*2) #2 data values
	for i in 1:nvals
		id = read(r, UInt32)
		offset = read(r, Int32)
		println("($id, offset=$offset)")
	end

	return nothing
end

#TraceIndex::deserialize
#Does not seem to do anything.
function deserialize(r::DataReader, ::Type{TraceIndex})
	deserialize_chunk(r, TraceIndex)
	_size = read(r, UInt32)

	nvals = div(_size, 4*4) #4 data values
	for i in 1:nvals
		id = read(r, UInt32)
		offset = read(r, Int32)
		extra1 = read(r, Int32)
		extra2 = read(r, Int32)
		println("($id, offset=$offset, extra1=$extra1, extra2=$extra2)")
	end

	return nothing
end

#DataTypeDef::deserialize
function deserialize(r::DataReader, child::DataTypeDef)
	deserialize_chunk(r, DataTypeDef)
	child.id = read(r, Int32)
	child.name = deserialize(r, String)
	arraytype = read(r, Int32)
	child.datatypeid = read(r, Int32)

	if 16 == child.datatypeid #Made up of other custom data elements
		child.structdef = StructDef()
		deserialize(r, child.structdef)
		child._datasize = child.structdef._datasize
#println(); @show child.name
#for e in child.structdef.childlist; (@show e); end
	else
		child._datasize = psfdata_size(child.datatypeid)
	end
	child.properties = deserialize(r, PropertyBlock)
	return child
end

#StructDef::deserialize
function deserialize(r::DataReader, s::StructDef)
	s._datasize = 0
	while true
		child = deserialize_child(r, StructDef)
		if nothing == child; break; end
		#BUG?: Need to re-assign - otherwise assertion executes before above if stmt.
		child = child::DataTypeDef #throw error if not right type
		push!(s.childlist, child)
		s._datasize += child._datasize
	end
	return s
end

#DataTypeRef::deserialize
function deserialize(r::DataReader, child::DataTypeRef)
	deserialize_chunk(r, DataTypeRef)
	child.id = read(r, Int32)
	child.name = deserialize(r, String)
	child.datatypeid = read(r, Int32)
	child.properties = deserialize(r, PropertyBlock)
	return child
end

#Struct::deserialize
function deserialize(r::DataReader, def::StructDef, ::Type{Struct})
	result = StructDict()
	for elemdef in def.childlist
		T = psfdata_type(elemdef)
		val = read(r, T)
		result[elemdef.name] = val
	end
	return result
end

function deserialize(r::DataReader, child::NonSweepValue)
	deserialize_chunk(r, NonSweepValue)
	child.id = read(r, Int32)
	child.name = deserialize(r, String)
	child.valuetypeid = read(r, Int32)

	def = get_typedef(r.types, child.valuetypeid)
		T = psfdata_type(def)
	if T <: Struct
		child.value = deserialize(r, def.structdef, Struct)
	else
		child.value = deserialize(r, T)
	end
	child.propblock = deserialize(r, PropertyBlock)
	return child
end

#GroupDef::deserialize
function deserialize(r::DataReader, child::GroupDef)
	deserialize_chunk(r, GroupDef)
	child.id = read(r, Int32)
	child.name = deserialize(r, String)

	child.nchildren = read(r, Int32)
	#TODO: resize in a single call instead of pushing?

	for i in 1:child.nchildren
		chunk = deserialize_child(r, GroupDef)
		push!(child.childlist, chunk)
		child.namemap[chunk.name] = i #TODO: use i-1??
		child.indexmap[chunk.id] = i #TODO: use i-1??
	end

	return child
end

#Container::deserialize_child
#TODO: rename??
function deserialize_child(r::DataReader, T::Type)
	pos = position(r.io)
	childtype = read(r, Int32)
#@show T, childtype, pos
	child = child_factory(childtype, T)

	if (child != nothing)
		seek(r.io, pos) #Rewind back to same byte
		deserialize(r, child)
	#else: An endmarker was found and its chunk type was consumed.
	end

	return child
end

#SimpleContainer::deserialize
#TODO: rename??
function deserialize_container(r::DataReader, section::T) where T<:Section
	seek(r.io, section.info.offset)
	deserialize_chunk(r, T)
	endpos = read(r, UInt32)
#@show Int(endpos), section.info.offset+section.info.size

	while position(r.io) < endpos
		chunk = deserialize_child(r, T)
		if chunk != nothing
			push!(section.childlist, chunk)
		else
			break
		end
	end
	return section
end

#IndexedContainer::deserialize
function deserialize_container(r::DataReader, section::T) where T<:IndexedSection
	seek(r.io, section.info.offset)
	deserialize_chunk(r, T)
	endpos = read(r, UInt32)
#@show Int(endpos), section.info.offset+section.info.size

	#Sub container
	subcontainer_typeid = read(r, UInt32)

	if(subcontainer_typeid != 22)
		throw("Subcontainer id not found.")
	end

	subendpos = read(r, UInt32)
	while position(r.io) < subendpos
		chunk = deserialize_child(r, T)
		if chunk != nothing
			push!(section.childlist, chunk)
		else
			break
		end
	end

#=
	#DO NOT RUN: (Don't see results being used.)
	local index
	if TraceSection == T
		index = deserialize(r, TraceIndex)
	else
		index = deserialize(r, Index)
	end
=#

	for i in 1:length(section.childlist)
		child = section.childlist[i]
		section.idmap[child.id] = child
		section.namemap[child.name] = i #TODO: use i-1?
	end

	return section #Relay back data
end

#SimpleContainer::deserialize (when no specialization defined)
#or IndexedContainer::deserialize (when no specialization defined)
#SweepSection, 
function deserialize(r::DataReader, section::Section)
	return deserialize_container(r, section)
end

#HeaderSection::deserialize
function deserialize(r::DataReader, section::HeaderSection)
	result = PropDict()
	deserialize_container(r, section)
	for child in section.childlist
		ctype = typeof(child)
		if ctype != Property
			throw("Invalid Child: $ctype")
		end
		push!(result, child.name => child.value)
	end
	return result
end

#ValueSectionSweep::deserialize
function deserialize(r::DataReader, section::ValueSectionSweep)
	seek(r.io, section.info.offset)
	deserialize_chunk(r, ValueSectionSweep)
	section.endpos = read(r, UInt32)

	if section.windowsize > 0
		deserialize(r, ZeroPad)
	end

	create_valueoffsetmap(r, section)
	section.curpos = position(r.io)

	return section
end


#PSFFile::deserialize
function deserialize_file(r::DataReader)
	#Last word contains the size of the data:
	_size = r.filesize
	seek(r.io, _size-4)

	#Read section index table:
	datasize = read(r, UInt32)

	nsections = div(_size - datasize - 12, 8);
	lastoffset = 0; lastsectionnum = -1;

	toc = _size - 12 - nsections*8;

	sections = Dict{Int,Section}()
	sectioninfo = SectionInfo()
	sectionid = -1
	for i in 1:nsections
		seek(r.io, toc+8*(i-1))
		sectionid = read(r, UInt32);
		sectioninfo.offset = read(r, UInt32);

		if (i>1)
			sections[lastsectionnum].info.size = sectioninfo.offset - lastoffset;
		end

		sections[sectionid] = Section(Int(sectionid), sectioninfo);

		lastoffset = sectioninfo.offset;
		lastsectionnum = sectionid;
	end
	sections[sectionid].info.size = _size - sectioninfo.offset;
#display(sections)

	#Read in header:
	r.properties = deserialize(r, sections[SECTION_HEADER])

	#Read types:
	section = get(sections, SECTION_TYPE, nothing)
	if section != nothing
		r.types = deserialize(r, section)
	end

	#Read sweeps:
	section = get(sections, SECTION_SWEEP, nothing)
	sweeps = section
	if section != nothing
		r.sweeps = deserialize(r, section)
	end

	#Read traces:
	section = get(sections, SECTION_TRACE, nothing)
	if section != nothing
		r.traces = deserialize(r, section)
	end

	section = get(sections, SECTION_VALUE, nothing)
	if section != nothing
		if sweeps != nothing
			windowsize = get(r.properties, "PSF window size", 0)
			section = ValueSectionSweep(section.info, windowsize)
			r.sweepvalues = deserialize(r, section)
		else
			section = ValueSectionNonSweep(section.info)
			r.nonsweepvalues = deserialize(r, section)
		end
	end
end

#Last Line
