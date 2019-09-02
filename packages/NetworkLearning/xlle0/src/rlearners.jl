# Types
abstract type AbstractRelationalLearner end

"""
Simple relational neighbour learner. Counts for 
each vertex how many neighbours from each class
are in its neighbourhood.
"""
struct SimpleRN{T<:LearnBase.ObsDimension} <: AbstractRelationalLearner 
	obsdim::T
	normalize::Bool
end

"""
Weighted relational neighbour learner. For each
vertex, it sums up the estimates from neighboring
vertices. 
"""
struct WeightedRN{T<:LearnBase.ObsDimension}<: AbstractRelationalLearner 
	obsdim::T
	normalize::Bool
end

"""
Naive-Bayes relational neighbour learner (trainable). 
Calculates neighbourhood likelihoods (i.e. given a vertex's class, 
the class distribution in its neighbourhood)
and uses the resulting information to compute class
estimates for each vertex using a Bayesian approach.
"""
struct BayesRN{T<:LearnBase.ObsDimension}<: AbstractRelationalLearner 
	obsdim::T
	priors::Vector{Float64}
	normalize::Bool
	LM::Matrix{Float64}	# likelihood matrix (class-conditional neighbourhood likelihoods)
end

"""
Class-distribution relational neighbour (trainable).
Claculates a reference vector (RV) for each class (using
the vertex neighbourhood information) and compares
vertices to the reference vectors corresponding to each
class using a similarity measure.
"""
struct ClassDistributionRN{T<:LearnBase.ObsDimension} <: AbstractRelationalLearner
	obsdim::T
	normalize::Bool
	RV::Matrix{Float64}
end



# Aliases
const SimpleRNRowMajor = SimpleRN{<:ObsDim.Constant{1}}
const SimpleRNColumnMajor = SimpleRN{<:ObsDim.Constant{2}}

const WeightedRNRowMajor = WeightedRN{<:ObsDim.Constant{1}}
const WeightedRNColumnMajor = WeightedRN{<:ObsDim.Constant{2}}

const BayesRNRowMajor = BayesRN{<:ObsDim.Constant{1}}
const BayesRNColumnMajor = BayesRN{<:ObsDim.Constant{2}}

const ClassDistributionRNRowMajor = ClassDistributionRN{<:ObsDim.Constant{1}}
const ClassDistributionRNColumnMajor = ClassDistributionRN{<:ObsDim.Constant{2}}



# Show methods
Base.show(io::IO, rl::SimpleRNColumnMajor) = print(io, "RN, column-major, normalize=$(rl.normalize)")
Base.show(io::IO, rl::WeightedRNColumnMajor) = print(io, "wRN, column-major, normalize=$(rl.normalize)")
Base.show(io::IO, rl::BayesRNColumnMajor) = print(io, "bayesRN, column-major, normalize=$(rl.normalize), $(length(rl.priors)) classes")
Base.show(io::IO, rl::ClassDistributionRNColumnMajor) = print(io, "cdRN, column-major, normalize=$(rl.normalize), $(size(rl.RV,2)) classes")

Base.show(io::IO, rl::SimpleRNRowMajor) = print(io, "RN, row-major, normalize=$(rl.normalize)")
Base.show(io::IO, rl::WeightedRNRowMajor) = print(io, "wRN, row-major, normalize=$(rl.normalize)")
Base.show(io::IO, rl::BayesRNRowMajor) = print(io, "bayesRN, row major, normalize=$(rl.normalize), $(length(rl.priors)) classes")
Base.show(io::IO, rl::ClassDistributionRNRowMajor) = print(io, "cdRN, row major, normalize=$(rl.normalize), $(size(rl.RV,2)) classes")

Base.show(io::IO, vrl::T) where T<:AbstractVector{S} where S<:AbstractRelationalLearner = 
	print(io, "$(length(vrl))-element Vector{$S} ...")


# Training methods (all fit mehods use the same unique signature)
fit(::Type{SimpleRN}, args...; obsdim::T=ObsDim.Constant{2}(), priors::Vector{Float64}=Float64[], 
    		normalize::Bool=true) where T<:LearnBase.ObsDimension =
	SimpleRN(obsdim, normalize)

fit(::Type{WeightedRN}, args...; obsdim::T=ObsDim.Constant{2}(), priors::Vector{Float64}=Float64[], 
    		normalize::Bool=true) where T<:LearnBase.ObsDimension =
	WeightedRN(obsdim, normalize)

fit(::Type{BayesRN}, Ai::AbstractAdjacency, Xl::AbstractMatrix, y::AbstractVector; 
    		obsdim::T=ObsDim.Constant{2}(), priors::Vector{Float64}=ones(nvars(Xl,obsdim)), 
		normalize::Bool=true) where T<:LearnBase.ObsDimension =
begin
	C = nvars(Xl,obsdim)
	@assert C == length(priors) "Size of local model estimates is $(C) and prior vector length is $(length(priors))."

	# Get for each observation class percentages in neighbourhood
	Am = adjacency_matrix(Ai)
	H = vcat((sum(Am[y.==i,:], dims=1) for i in 1:C)...) ./clamp!(sum(Am, dims=1),1.0,Inf)
	
	# Calculate the means of neighbourhood class percentages for all samples belonging to the same class 
	LM = zeros(C,C)
	@inbounds @simd for c in 1:C
		LM[:,c] = mean(H[:,y.==c], dims=2)
	end

	BayesRN(obsdim, priors, normalize, LM)
end

fit(::Type{ClassDistributionRN}, Ai::AbstractAdjacency, Xl::AbstractMatrix, y::AbstractVector; 
    		obsdim::LearnBase.ObsDimension=ObsDim.Constant{2}(), 
		priors::Vector{Float64}=ones(nvars(Xl,obsdim)), normalize::Bool=true) = 
begin
	yu = sort(unique(y))
	n = nvars(Xl,obsdim)
	RV = zeros(n,n) 			# RV is a matrix where columns correspond to the class vectors of each class;
	
	# Calculate reference vectors (matrix where each column is a reference vector)
	Am = adjacency_matrix(Ai)
	if obsdim isa ObsDim.Constant{2}
		Xtmp = Xl * adjacency_matrix(Am)
	else
		Xtmp = (adjacency_matrix(Am) * Xl)'
	end
	
	Xtmp ./= clamp!(sum(Am, dims=1),1.0,Inf)# normalize to edge weight sum
	
	@inbounds @simd for i in 1:n
		RV[:,i] = mean(view(Xtmp,:,y.==yu[i]), dims=2)
	end
	
	return ClassDistributionRN(obsdim, normalize, RV)
end



# Transform methods
function transform!(Xr::T, Rl::R, Ai::AbstractAdjacency, X::S, ŷ::U) where {
		R<:AbstractRelationalLearner, T<:AbstractMatrix, S<:AbstractVector, U<:AbstractVector}
	Am = adjacency_matrix(Ai)
	transform!(Xr, Rl, Am, X', ŷ)
end

function transform!(Xr::T, Rl::R, Ai::AbstractAdjacency, X::S, ŷ::U) where {
		R<:AbstractRelationalLearner, T<:AbstractMatrix, S<:AbstractMatrix, U<:AbstractVector}
	Am = adjacency_matrix(Ai)
	transform!(Xr, Rl, Am, X, ŷ)
end

function transform!(Xr::T, Rl::SimpleRNColumnMajor, Am::M, X::S, ŷ::U) where {
		T<:AbstractMatrix, M<:AbstractMatrix, S<:AbstractMatrix, U<:AbstractVector}	
	for i in 1:size(Xr,1)
		Xr[i,:] = transpose(ŷ.==i) * Am	# summate edge weights for neighbours in class 'i'
	end
	Xr ./= clamp!(sum(Am, dims=1),1.0,Inf)	# normalize to edge weight sum
	
	if Rl.normalize				# normalize estimates / observation
		Xr ./= sum(Xr.+eps(), dims=1)
	end
	return Xr
end

function transform!(Xr::T, Rl::SimpleRNRowMajor, Am::M, X::S, ŷ::U) where {
		T<:AbstractMatrix, M<:AbstractMatrix, S<:AbstractMatrix, U<:AbstractVector}	
	for i in 1:size(Xr,2)
		Xr[:,i] = transpose(ŷ.==i) * Am	# summate edge weights for neighbours in class 'i'
	end
	Xr ./= clamp!(vec(sum(Am, dims=1)),1.0,Inf)	# normalize to edge weight sum
	
	if Rl.normalize				# normalize estimates / observation
		Xr ./= sum(Xr.+eps(), dims=2)
	end
	return Xr
end

function transform!(Xr::T, Rl::WeightedRNColumnMajor, Am::M, X::S, ŷ::U) where {
		T<:AbstractMatrix, M<:AbstractMatrix, S<:AbstractMatrix, U<:AbstractVector}	
	mul!(Xr, X, Am)				# summate edge weighted probabilities of all neighbors
	Xr ./= clamp!(sum(Am, dims=1),1.0,Inf)	# normalize to edge weight sum
	
	if Rl.normalize				# normalize estimates / observation
		Xr ./= sum(Xr.+eps(), dims=1)
	end
	return Xr
end

function transform!(Xr::T, Rl::WeightedRNRowMajor, Am::M, X::S, ŷ::U) where {
		T<:AbstractMatrix, M<:AbstractMatrix, S<:AbstractMatrix, U<:AbstractVector}	
	mul!(Xr, transpose(Am), X)		# summate edge weighted probabilities of all neighbors
	Xr ./= clamp!(vec(sum(Am, dims=1)),1.0,Inf)	# normalize to edge weight sum
	
	if Rl.normalize				# normalize estimates / observation
		Xr ./= sum(Xr.+eps(), dims=2)
	end
	return Xr
end

function transform!(Xr::T, Rl::BayesRNColumnMajor, Am::M, X::S, ŷ::U) where {
		T<:AbstractMatrix, M<:AbstractMatrix, S<:AbstractMatrix, U<:AbstractVector}	
	Xt = zero(Xr)				# initialize temporary output relational data with 0
	Sw = clamp!(sum(Am, dims=1),1.0,Inf)	# sum all edge weights for all nodes
	Swi = zero(Sw)
	@inbounds @simd for i in 1:size(Xt,1)
		Swi = sum(Am[ŷ.==i,:], dims=1)./Sw	# get normalized sum of edges of neighbours in class 'i', for all nodes
		Xt += log1p.(Rl.LM[:,i])*Swi	# add weighted class 'i' log likelihoods for all samples
	end
		
	Xt = Xt.+ Rl.priors
	Xr[:] = Xt
	if Rl.normalize				# normalize estimates / observation
		Xr ./= sum(Xr.+eps(), dims=1)
	end
	return Xr
end

function transform!(Xr::T, Rl::BayesRNRowMajor, Am::M, X::S, ŷ::U) where {
		T<:AbstractMatrix, M<:AbstractMatrix, S<:AbstractMatrix, U<:AbstractVector}	
		
	Xt = zeros(size(Xr,2), size(Xr,1))	# initialize temporary output relational data with 0
	Sw = clamp!(sum(Am, dims=1),1.0,Inf)	# sum all edge weights for all nodes
	Swi = zero(Sw)
	@inbounds @simd for i in 1:size(Xt,1)
		Swi = sum(Am[ŷ.==i,:], dims=1)./Sw	# get normalized sum of edges of neighbours in class 'i', for all nodes
		Xt += log1p.(Rl.LM[:,i])*Swi	# add weighted class 'i' log likelihoods for all samples
	end

	Xt = Xt.+ Rl.priors
	Xr[:] = Xt'
	if Rl.normalize				# normalize estimates / observation
		Xr ./= sum(Xr.+eps(), dims=2)
	end
	return Xr
end

function transform!(Xr::T, Rl::ClassDistributionRNColumnMajor, Am::M, X::S, ŷ::U) where {
		T<:AbstractMatrix, M<:AbstractMatrix, S<:AbstractMatrix, U<:AbstractVector}	
	d = Distances.Euclidean()
	Xtmp = X*Am
	Xtmp ./= clamp!(sum(Am, dims=1),1.0,Inf)# normalize to edge weight sum
		
	Distances.pairwise!(Xr, d, Rl.RV, Xtmp)	
	
	if Rl.normalize				# normalize estimates / observation
		Xr ./= sum(Xr.+eps(), dims=1)
	end

	return Xr
end

function transform!(Xr::T, Rl::ClassDistributionRNRowMajor, Am::M, X::S, ŷ::U) where {
		T<:AbstractMatrix, M<:AbstractMatrix, S<:AbstractMatrix, U<:AbstractVector}	
	d = Distances.Euclidean()
	Xtmp = transpose(Am) * X
	Xtmp ./= clamp!(vec(sum(Am, dims=1)),1.0,Inf)	# normalize to edge weight sum
	Xtmp = Distances.pairwise(d, Rl.RV, Xtmp')	
	
	Xr[:] = Xtmp'
	if Rl.normalize				# normalize estimates / observation
		Xr ./= sum(Xr.+eps(), dims=2)
	end

	return Xr
end
