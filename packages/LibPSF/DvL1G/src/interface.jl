#LibPSF: Main interface
#-------------------------------------------------------------------------------


#==High-level functions
===============================================================================#
#=PSFDataset: Methods:
    const std::vector<std::string> get_signal_names() const;
    bool is_swept() const;
    int get_nsweeps() const;
    const std::vector<std::string> get_sweep_param_names() const;
    int get_sweep_npoints() const;
    PSFVector *get_sweep_values() const;
    PSFVector *get_signal_vector(std::string name) const;
    const PSFScalar& get_signal_scalar(std::string name) const;
    PSFBase *get_signal(std::string name) const; //Returns either vector or scalar
=#

#PSFDataSet::is_swept
is_swept(reader::DataReader) =
	get(reader.properties, "PSF sweeps", 0) > 0

#PSFDataSet::get_nsweeps
get_nsweeps(reader::DataReader) = #Throws error if no sweep
	get(reader.properties, "PSF sweeps")

#PSFDataSet::get_sweep_npoints
get_sweep_npoints(reader::DataReader) = #Throws error if no npoints
	get(reader.properties, "PSF sweep points")

#SweepSection::get_names
function get_names(section::SweepSection)
	result = String[]
	for child in section.childlist
		push!(result, child.name)
	end
	return result
end


#Container::get_names
function get_names(grp::GroupDef)
	result = String[]
	for child in grp.childlist
		push!(result, child.name)
	end
	return result
end

#TraceSection::get_names
function get_names(section::TraceSection)
	result = String[]
	for child in section.childlist
		if typeof(child) <: GroupDef
			append!(result, get_names(child))
		else #child should be: DataTypeRef
			push!(result, child.name)
		end
	end
	return result
end

#Container::get_names
function get_names(v::ValueSectionNonSweep)
	result = String[]
	for child in v.childlist
		push!(result, child.name)
	end
	return result
end

#PSFDataSet::get_signal_names/PSFFile::get_names
function get_signal_names(reader::DataReader)
	if reader.traces != nothing
		get_names(reader.traces)
	elseif reader.nonsweepvalues != nothing
		get_names(reader.nonsweepvalues)
	else
		throw("No names found.")
	end
end

#PSFDataSet::get_sweep_param_names/PSFFile::get_param_names
function get_sweep_param_names(reader::DataReader)
	if reader.sweeps != nothing
		return get_names(reader.sweeps)
	else
		return String[]
	end
end

#Get values from a list of Chunk elements (filter)
#ValueSectionSweep::get_values
function get_values(reader::DataReader, filter::ChunkFilter)
	value = new_value(reader.sweepvalues)
	n = reader.properties["PSF sweep points"]
	windowoffset = 0

	#TODO: move seek inside deserialize??
	seek(reader.io, reader.sweepvalues.curpos)
	return deserialize(reader, value, n, windowoffset, filter)
end

#Get main sweep (param) values
#PSFDataSet::get_sweep_values / PSFFile::get_param_values
#Main code from: ValueSectionSweep::get_param_values
function get_sweep_values(reader::DataReader)
	if nothing == reader.sweepvalues
		return nothing
	end
	filter = ChunkFilter() #No y-values?
	v = get_values(reader, filter)
	#No need to clear values (v will go out of scope)
	return v.paramvalues
end

#TraceSection::get_trace_by_name
function get_trace_by_name(section::TraceSection, signame::String)
	try
		return get_child(section, signame)::DataTypeRef #Ensure correct type
	catch e
		for child in section.childlist
			if typeof(child) <: GroupDef
				return get_child(child, signame)::DataTypeRef #Ensure correct type
			end
		end
		rethrow(e)
	end
end

#PSFDataSet::get_signal_vector / PSFFile::get_values
#Main code from: ValueSectionSweep::get_values
function get_signal_vector(reader::DataReader, signame::String)
	if nothing == reader.sweepvalues
		return nothing
	end
	#Create filter for retrieving the trace with correct name
	filter = ChunkFilter()
	push!(filter, get_trace_by_name(reader.traces, signame))
	v = get_values(reader, filter)
	#No need to clear values (v will go out of scope)
	return v.vectorlist[1]
end

#PSFDataSet::get_signal_scalar / PSFFile::get_value
#Main code from: ValueSectionNonSweep::get_value
function get_signal_scalar(reader::DataReader, signame::String)
	if nothing == reader.nonsweepvalues
		throw("No non-sweep values")
	end
	#Assert type:
	val = get_child(reader.nonsweepvalues, signame)::NonSweepValue
	return val.value
end

#PSFDataSet::get_signal
function get_signal(reader::DataReader, signame::String)
	if is_swept(reader)
		vec = get_signal_vector(reader, signame)
#=
		if(m_invertstruct && dynamic_cast<const StructVector *>(vec)) {
			VectorStruct *vs = new VectorStruct(*dynamic_cast<const StructVector *>(vec));
			delete vec;
			return vs;
		} else
=#
			return vec
		#end
	else
		return get_signal_scalar(reader, signame)
	end
end


#==User-level functions
===============================================================================#
Base.names(reader::DataReader) = get_signal_names(reader)
readsweep(reader::DataReader) = get_sweep_values(reader)
Base.read(reader::DataReader, signame::String) = get_signal(reader, signame)


#==Open/close/read functions
===============================================================================#
#PSFFile::open
function _open(filepath::String)
	io = open(filepath)
	reader = DataReader(io, filepath)
	seekend(io)
	reader.filesize = position(io)
	seek(io, 0)
	deserialize_file(reader)
	return reader
end

Base.close(reader::DataReader) = close(reader.io)

#Last line
