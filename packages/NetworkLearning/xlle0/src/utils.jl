#################################################################
###### Functionality related to observation dimensionality ######
#################################################################
		# Note: The functions are designed to work on two 
		# dimensional data containers (i.e. matrices)

# Opposide dimension function
"""
	oppdim(::LearnBase.ObsDimension)

Returns the other dimension for a matrix i.e. if provided `ObsDim.Constant{1}` 
returns `ObsDim.Constant{2}`.
"""
oppdim(::ObsDim.First) = ObsDim.Constant{2}()
oppdim(::ObsDim.Last) = ObsDim.First()
oppdim(::ObsDim.Constant{2}) = ObsDim.Constant{1}()



# get integer dimension
"""
	intdim(::LearnBase.ObsDimension)

Returns the integer associated to a dimension object 
i.e. `intdim(ObsDim.Constant{3})`  returns `3`. 
The function is designed to work on matices so 
`intdim(::ObsDim.Last)` will return `2`.
"""
intdim(::ObsDim.First) = 1 
intdim(::ObsDim.Last) = 2
intdim(::ObsDim.Constant{N}) where N = N



# nvars function
"""
Returns the number of variables given a data object which 
supports the `nobs` function. The data object must ideally 
present two dimensions i.e. matrix.
"""
nvars(X, arg) = nobs(X,oppdim(arg))



# pre-allocation
"""
	matrix_prealloc(no, nv, obsdim, val)

Returns a `Matrix{T}` filled with values equal to `val::T`, having
the size `no` (number of observations) on dimension `obsdim` and 
`nv` (number of variables) in the other dimension.
"""
function matrix_prealloc(no::Int, nv::Int, obsdim::O, val::T=zero(T)) where {
		T,O <:LearnBase.ObsDimension}
	# get dimensions (inner function)
	_getdims_(no, nv, ::ObsDim.First) = no, nv
	_getdims_(no, nv, ::ObsDim.Last) = nv, no
	_getdims_(no, nv, ::ObsDim.Constant{2}) = nv, no
	_getdims_(no, nv, ::ObsDim.Undefined) = error("Undefined observation dimension") 
		
	m,n = _getdims_(no, nv, obsdim)
	M = Array{T}(undef, m,n)
	fill!(M,val)

	return M
end



#################################################################
################# Additional utility functions ##################
#################################################################

# Function that calculates the number of  relational variables / each adjacency structure
get_size_out(y::AbstractVector{T}) where T<:Float64 = 1			# regression case
get_size_out(y::AbstractVector{T}) where T = length(unique(y))::Int	# classification case
get_size_out(y::AbstractArray) = error("Only vectors supported as targets in relational learning.")



# Function that calculates the priors of the dataset
getpriors(y::AbstractVector{T}) where T<:Float64 = [1.0]	
getpriors(y::AbstractVector{T}) where T = [sum(yi.==y)/length(y) for yi in sort(unique(y))]
getpriors(y::AbstractArray) = error("Only vectors supported as targets in relational learning.")



encode_targets(labels::T where T<:AbstractVector{S}) where S = begin
	ulabels::Vector{S} = sort(unique(labels))
	enc = LabelEnc.NativeLabels(ulabels)
	return (enc, label2ind.(labels,enc))
end

encode_targets(labels::T where T<:AbstractVector{S}) where S<:AbstractFloat = begin
	return (nothing, labels)
end

encode_targets(labels::T where T<:AbstractArray{S}) where S = begin
	error("Targets must be in vector form, other arrays not supported.")
end



read_citation_data(content_file::String, cites_file::String) = begin
              
	# Read files
	content = readdlm(content_file,'\t')
	cites = readdlm(cites_file,'\t')
		      
	# Construct datasets
	labels = content[:,end]
	paper_ids = Int.(content[:,1])
	data = Float64.(content[:,2:end-1]')
	content_data = (data, labels)

	# Construct citing/cited paper indices
	cited_papers = indexin(Int.(cites[:,1]), paper_ids)
	citing_papers = indexin(Int.(cites[:,2]), paper_ids)

	return content_data, cited_papers, citing_papers

end



# Function that grabs the Cora dataset
grab_cora_data(tmpdir::String="/tmp") = begin
	
	DATA_FILE = download("https://linqs-data.soe.ucsc.edu/public/lbc/cora.tgz")
	run(`tar zxvf $(DATA_FILE) -C $tmpdir`)
	
	cora_data = read_citation_data("$tmpdir/cora/cora.content","$tmpdir/cora/cora.cites")
	
	run(`rm -rf $tmpdir/cora`)
	run(`rm $DATA_FILE`)
	
	return cora_data
end



# Function that generates an adjacency matrix based on the citing and cited paper indices as well as 
# the indices in these vectors of the citations that are to be considered
function generate_partial_adjacency(cited::T, citing::T, useidx::S) where {T<:AbstractVector, S<:AbstractVector}

	# Search which citing/cited papers appear in the subset indices
	citing_idx = indexin(cited, useidx)
	cited_idx = indexin(citing, useidx)

	# Construct adjacency
	n = length(useidx)
	W = zeros(n,n)
	for i in 1:length(citing)
	  if citing_idx[i] != nothing && cited_idx[i] != nothing
	      W[citing_idx[i],cited_idx[i]] += 1
	      W[cited_idx[i],citing_idx[i]] += 1
	  end
	end
	return W
end



macro print_verbose(level, message)
	esc( :(
	 	NetworkLearning.VERBOSE >= 0 && 
	 	NetworkLearning.VERBOSE >= $level && 
	 	print_with_color(:cyan, "[Network Learning] $($message)\n")
		)
	)
end

