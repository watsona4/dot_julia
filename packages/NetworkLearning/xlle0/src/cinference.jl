# Types
abstract type AbstractCollectiveInferer end

"""
Relaxation labeling object. Stores the parameters necessary for
the algorithm.
"""
struct RelaxationLabelingInferer <: AbstractCollectiveInferer 
	maxiter::Int
	tol::Float64
	tf::Function
	κ::Float64	
	α::Float64
end

"""
Iterative classification object. Stores the parameters necessary for
the algorithm.
"""
struct IterativeClassificationInferer <: AbstractCollectiveInferer 
	maxiter::Int
	tol::Float64
	tf::Function
end

"""
Gibbs sapmpling object. Stores the parameters necessary for
the algorithm.
"""
struct GibbsSamplingInferer <: AbstractCollectiveInferer 
	maxiter::Int
	tol::Float64
	tf::Function
	burniter::Int
end



# Show methods
Base.show(io::IO, ci::RelaxationLabelingInferer) = print(io, "Relaxation labeling, maxiter=$(ci.maxiter), tol=$(ci.tol), κ=$(ci.κ), α=$(ci.α)")
Base.show(io::IO, ci::IterativeClassificationInferer) = print(io, "Iterative classification, maxiter=$(ci.maxiter), tol=$(ci.tol)")
Base.show(io::IO, ci::GibbsSamplingInferer) = print(io, "Gibbs sampling, maxiter=$(ci.maxiter), tol=$(ci.tol), burniter=$(ci.burniter)")
Base.show(io::IO, vci::T) where T<:AbstractVector{S} where S<:AbstractCollectiveInferer = 
	print(io, "$(length(vci))-element Vector{$S} ...")



# Transform methods
function transform!(Xo::T, Ci::RelaxationLabelingInferer, obsdim::OD, Mr::M, fr_exec::E, RL::R, Adj::A, offset::Int, Xr::S, 
		    update::BitVector=trues(nobs(Xo))) where {
		M, E, 
		OD<:LearnBase.ObsDimension,
		T<:AbstractMatrix, R<:Vector{<:AbstractRelationalLearner}, 
		A<:Vector{<:AbstractAdjacency}, S<:AbstractMatrix}
	
	# Initializations
	n = nobs(Xo, obsdim)									# number of observations
	κ = Ci.κ										# a constant between 0 and 1
	α = Ci.α										# decay
	β = κ											# weight of current iteration estimates
	maxiter = Ci.maxiter									# maximum number of iterations
	tol = Ci.tol										# maximum error 
	f_targets = Ci.tf									# function used to obtain targets
	size_out = nvars(Xo,obsdim)								# ouput size (corresponds to the number of classes)
	Xl = copy(Xo)										# local estimates
	ŷ = f_targets(Xo)									# Obtain first the labels corresponding to the local model
	ŷₒ = similar(ŷ)										#   and the 'previous' iteration estimates
	AV = adjacency_matrix.(Adj)								# Pre-calculate adjacency matrices
	Xrᵢ = matrix_prealloc(n, size_out, obsdim, 0.0)						# Initialize temporary storage	

	# Iterate
	_Xo = datasubset(Xo, update, obsdim)
	_Xr = datasubset(Xr, update, obsdim) 
	for it in 1:maxiter
		β = β * α									# Update learning rate
		copy!(ŷₒ, ŷ);									# Update 'previous iteration' estimates 
		
		# Obtain relational dataset for the current iteration
		@inbounds for (i,(RLᵢ,Aᵢ)) in enumerate(zip(RL,AV))		
		
			# Apply relational learner
			transform!(Xrᵢ, RLᵢ, Aᵢ, Xo, ŷ)

			# Update relational data output
			_Xrᵢ= datasubset(Xr, offset+(i-1)*size_out+1 : offset+i*size_out, oppdim(obsdim))
			_Xrᵢ[:] = Xrᵢ
		end
		
		# Update estimates
		
		_Xo[:] = β.*fr_exec(Mr, _Xr) + (1.0-β).*_Xo 
		ŷ = f_targets(Xo)

		# Convergence check
		if isequal(ŷ,ŷₒ) || mean(abs.(ŷ-ŷₒ))<=tol
			@print_verbose 1 "Convergence reached at iteration $it."
			break
		else
			@print_verbose 2 "\tIteration $it: $(sum(ŷ.!= ŷₒ)) estimates changed"
	   	end
		
		# Replace non-converging estimates with local estimates
		if (it == maxiter) && (maxiter != 1)
			_nc = ŷ.!=ŷₒ 		# positions of non-converging estimates
			datasubset(Xo, _nc, obsdim)[:] = datasubset(Xl, _nc, obsdim)[:]
			@print_verbose 1 "Maximum level of iterations reached, $(sum(_nc)) estimates did not converge."
		end
	end
	
	return Xo
end

function transform!(Xo::T, Ci::IterativeClassificationInferer, obsdim::OD, Mr::M, fr_exec::E, RL::R, Adj::A, offset::Int, Xr::S,
		    update::BitVector=trues(nobs(Xo))) where {
		M, E, 
		OD<:LearnBase.ObsDimension,
		T<:AbstractMatrix, R<:Vector{<:AbstractRelationalLearner}, 
		A<:Vector{<:AbstractAdjacency}, S<:AbstractMatrix}
	
	# Initializations
	n = nobs(Xr,obsdim)									# number of observations 
	ordering = [i:i for i in findall(update)]						# observation estimation order
	maxiter = Ci.maxiter									# maximum number of iterations
	tol = Ci.tol										# maximum error 
	f_targets = Ci.tf									# function used to obtain targets
	size_out = nvars(Xo,obsdim)								# ouput size (corresponds to the number of classes)
	Xl = copy(Xo)										# local estimates	
	ŷ = f_targets(Xo)									# Obtain first the labels corresponding to the local model
	ŷₒ = similar(ŷ)										#   and the 'previous' iteration estimates
	AV = adjacency_matrix.(Adj)								# Pre-calculate adjacency matrices
	Xrᵢⱼ = matrix_prealloc(1, size_out, obsdim, 0.0)					# Initialize temporary storage	
	second_dim = ObsDim.Constant{2}()

	# Iterate
	for it in 1:maxiter	
		shuffle!(ordering)								# Randomize observation order
		copy!(ŷₒ, ŷ);									# Update 'previous iteration' estimates 
		
		# Loop over observations and obtain individual estimates
		for rⱼ in ordering		
			
			# Get data subsets pertinent to the current observation 
			Xrⱼ = datasubset(Xr, rⱼ, obsdim)
			Xoⱼ = datasubset(Xo, rⱼ, obsdim)
			ŷⱼ = datasubset(ŷ, rⱼ)

			# Obtain relational data for the current observation
			@inbounds for (i,(RLᵢ,Aᵢ)) in enumerate(zip(RL,AV))

				# Apply relational learner
				Aᵢⱼ = adjacency_obs(Aᵢ, rⱼ, second_dim)
				transform!(Xrᵢⱼ, RLᵢ, Aᵢⱼ, Xo, ŷ)
												
				# Update relational data output for the current sample
				_Xrⱼ = datasubset(Xrⱼ, offset+(i-1)*size_out+1 : offset+i*size_out, oppdim(obsdim))
				_Xrⱼ[:] = Xrᵢⱼ
			end
		
			# Update estimates
			Xoⱼ[:] = fr_exec(Mr, Xrⱼ) 
			ŷⱼ[:] = f_targets(Xoⱼ)
		end

		# Convergence check
		if isequal(ŷ,ŷₒ) || mean(abs.(ŷ-ŷₒ))<=tol
			@print_verbose 1 "Convergence reached at iteration $it."
			break
		else
			@print_verbose 2 "\tIteration $it: $(sum(ŷ.!= ŷₒ)) estimates changed"
	   	end

		# Replace non-converging estimates with local estimates
		if (it == maxiter) && (maxiter != 1)
			_nc = ŷ.!=ŷₒ 		# positions of non-converging estimates
			datasubset(Xo, _nc, obsdim)[:] = datasubset(Xl, _nc, obsdim)[:]
			@print_verbose 1 "Maximum level of iterations reached, $(sum(_nc)) estimates did not converge."
		end
	end
	
	return Xo
end

# Version of Gibbs sampling (experimental) similar to iterative classification (i.e. no sampling) from: 
# P. Sen, G. Namata, M. Bilgic, L. Getoor, B. Gallagher, T. Eliassi-Rad "Collective classification in network data", AI Magazine 29(3), 2008

# Another (slower) alternative would be to assign to each observation a class sampled
# in accordance to the class-wise probabilities of its neighbourhood. This however
# implies 1. sampling (slow), 2. this would work only for relational learners that 
# make use of the neighbourhood class estimates (i.e. :rn and :bayesrn only)
function transform!(Xo::T, Ci::GibbsSamplingInferer, obsdim::OD, Mr::M, fr_exec::E, RL::R, Adj::A, offset::Int, Xr::S,
		    update::BitVector=trues(nobs(Xo))) where {
		M, E, 
		OD<:LearnBase.ObsDimension,
		T<:AbstractMatrix, R<:Vector{<:AbstractRelationalLearner}, 
		A<:Vector{<:AbstractAdjacency}, S<:AbstractMatrix}
	
	# Initializations
	n = nobs(Xr, obsdim)									# number of observations 
	updateable = findall(update)
	ordering = [i:i for i in updateable]							# observation estimation order 
	maxiter = Ci.maxiter									# maximum number of iterations
	burniter = Ci.burniter									# number of burn-in iterations
	tol = Ci.tol										# maximum error 
	f_targets = Ci.tf									# function used to obtain targets
	size_out = nvars(Xo,obsdim)								# ouput size (corresponds to the number of classes)
	Xl = copy(Xo)										# local estimates	
	ŷ = f_targets(Xo)									# Obtain first the labels corresponding to the local model
	ŷₒ = similar(ŷ)										#   and the 'previous' iteration estimates
	AV = adjacency_matrix.(Adj)								# Pre-calculate adjacency matrices
	Xrᵢⱼ = matrix_prealloc(1, size_out, obsdim, 0.0)					# Initialize temporary storage	
	second_dim = ObsDim.Constant{2}()

	# Burn-in
	@print_verbose 2 "\tRunning $burniter burn-in iterations ..."
	for it in 1:burniter
		shuffle!(ordering)								# Randomize observation order
	
		# Loop over observations and obtain individual estimates
		for rⱼ in ordering		
			
			# Get data subsets pertinent to the current observation 
			Xrⱼ = datasubset(Xr, rⱼ, obsdim)
			Xoⱼ = datasubset(Xo, rⱼ, obsdim)
			ŷⱼ = datasubset(ŷ, rⱼ)

			# Obtain relational data for the current observation
			@inbounds for (i,(RLᵢ,Aᵢ)) in enumerate(zip(RL,AV))		

				# Apply relational learner
				Aᵢⱼ = adjacency_obs(Aᵢ, rⱼ, second_dim)
				transform!(Xrᵢⱼ, RLᵢ, Aᵢⱼ, Xo, ŷ)
	
				# Update relational data output for the current sample
				_Xrⱼ = datasubset(Xrⱼ, offset+(i-1)*size_out+1 : offset+i*size_out, oppdim(obsdim))
				_Xrⱼ[:] = Xrᵢⱼ
			end
		
			# Update estimates
			Xoⱼ[:] = fr_exec(Mr, Xrⱼ) 
			ŷⱼ[:] = f_targets(Xoⱼ)
		end
	end	

	# Initialize class-counting structure
	class_counts = matrix_prealloc(n, size_out, obsdim, 0.0) 
	
	# Small function that makes the class count work (even though it does not make sense)
	# for cases outside classification (i.e. input labels are floats)
	_idx_(x::AbstractVector{Int}) = x[1]
	_idx_(x::AbstractVector) = 1
	# Iterate
	@print_verbose 2 "\tRunning $maxiter iterations ..."
	for it in 1:maxiter	
		shuffle!(ordering)								# Randomize observation order
		copy!(ŷₒ, ŷ);									# Update 'previous iteration' estimates 
		
		# Loop over observations and obtain individual estimates
		for rⱼ in ordering		
			
			# Get data subsets pertinent to the current observation 
			Xrⱼ = datasubset(Xr, rⱼ, obsdim)
			Xoⱼ = datasubset(Xo, rⱼ, obsdim)
			ŷⱼ = datasubset(ŷ, rⱼ)
			cⱼ = datasubset(class_counts, rⱼ, obsdim)
			
			# Obtain relational data for the current observation
			@inbounds for (i,(RLᵢ,Aᵢ)) in enumerate(zip(RL,AV))		

				# Apply relational learner
				Aᵢⱼ = adjacency_obs(Aᵢ, rⱼ, second_dim)
				transform!(Xrᵢⱼ, RLᵢ, Aᵢⱼ, Xo, ŷ) 				# TODO: Find a better compromise for adjacency access; views - slow for sparse matrices
												#	slicing - increases the number of allocations.
				# Update relational data output for the current sample
				_Xrⱼ = datasubset(Xrⱼ, offset+(i-1)*size_out+1 : offset+i*size_out, oppdim(obsdim))
				_Xrⱼ[:] = Xrᵢⱼ
			end
		
			# Update estimates
			Xoⱼ[:] = fr_exec(Mr, Xrⱼ) 
			ŷⱼ[:] = f_targets(Xoⱼ)
			cⱼ[_idx_(ŷⱼ)]+=1.0
		end
		
		# Convergence check
		if isequal(ŷ,ŷₒ) || mean(abs.(ŷ-ŷₒ))<=tol
			@print_verbose 1 "Convergence reached at iteration $it."
			break
		else
			@print_verbose 2 "\tIteration $it: $(sum(ŷ.!= ŷₒ)) estimates changed"
	   	end
	end
	
	# Assign new estimates
	_Xo = datasubset(Xo, updateable, obsdim)
	_cc = datasubset(class_counts, updateable, obsdim)
	_Xo[:] = _cc ./ sum(_cc, dims=intdim(oppdim(obsdim)))
	
	return Xo
end
