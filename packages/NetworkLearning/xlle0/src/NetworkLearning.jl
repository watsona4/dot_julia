# Network Learning
__precompile__(true)

"""
NetworkLearning implements a generic framework for network classification. It could in theory be used for other functionality such as regression and density estimation,
provided that appropriate methods for relational learning (i.e. relational variable generation) and collective inference are added. The framework is designed to make as little assumptions as possible on the elements involved in the process.  

# References
[1] S.A. Macskassy, F. Provost "Classification in networked data: A toolkit and a univariate case study", Journal of Machine learning Research 8, 2007, 935-983

[2] P. Sen, G. Namata, M. Bilgic, L. Getoor, B. Gallagher, T. Eliassi-Rad "Collective classification in network data", AI Magazine 29(3), 2008
"""
module NetworkLearning
	
	using LinearAlgebra, SparseArrays
	using Distances
	using LearnBase, MLDataPattern, MLLabelUtils
	using LightGraphs, SimpleWeightedGraphs
	using Random: shuffle!
	using Statistics: mean
	using DelimitedFiles: readdlm
	using Future: copy!
	
	# Verbosity level, used for debugging: 
	# 0 - off, 1 - minimal (i.e. warnings, convergence information), 2 - maximum (i.e. iteration details) 
	global const VERBOSE = 0 

	# Exports
	export  # Adjacencies
		AbstractAdjacency, 
		MatrixAdjacency,
		GraphAdjacency,
		ComputableAdjacency,
		PartialAdjacency,
		EmptyAdjacency,
		
		# Relational learners
		AbstractRelationalLearner,
		SimpleRN, 
		WeightedRN,
		BayesRN,
		ClassDistributionRN,

		# Collective inference
		AbstractCollectiveInferer, 
		RelaxationLabelingInferer,
		IterativeClassificationInferer,
		GibbsSamplingInferer,
		
		# Network learners
	 	AbstractNetworkLearner,
		NetworkLearnerObs,
		NetworkLearnerEnt,

		# Functionality	
		@print_verbose,
		fit, 
		predict, 
		predict!,
		infer!,
		transform, 
		transform!, 
		adjacency,
		add_adjacency!, 
		update_adjacency!,
		strip_adjacency,
		adjacency_matrix,
		adjacency_graph,
		adjacency_obs,
		intdim, 
		oppdim, 
		matrix_prealloc

	abstract type AbstractNetworkLearner end
	
	include("utils.jl")									# Small utility functions
	include("adjacency.jl") 								# Adjacency-related structures 
	include("rlearners.jl")									# Relational learners
	include("cinference.jl")								# Collective inference algorithms		
	include("obslearning.jl")								# Observation-based learning
	include("entlearning.jl")								# Entity-based learning

end
