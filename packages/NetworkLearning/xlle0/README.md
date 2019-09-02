# NetworkLearning

A Julia package for network learning.

[![License](http://img.shields.io/badge/license-MIT-brightgreen.svg?style=flat)](LICENSE.md) 
[![NetworkLearning](http://pkg.julialang.org/badges/NetworkLearning_0.6.svg)](http://pkg.julialang.org/detail/NetworkLearning)
[![Build Status](https://travis-ci.org/zgornel/NetworkLearning.jl.svg?branch=master)](https://travis-ci.org/zgornel/NetworkLearning.jl) 
[![Coverage Status](https://coveralls.io/repos/github/zgornel/NetworkLearning.jl/badge.svg?branch=master)](https://coveralls.io/github/zgornel/NetworkLearning.jl?branch=master)

## Introduction

NetworkLearning implements a generic framework for network classification. It could in theory be used to provide additional functionality (i.e. semi-supervised learning, regression),
provided that appropriate methods for relational learning (i.e. relational variable generation) and collective inference are added. The framework is designed to make as little assumptions as possible on the elements involved in the process.  

Two scenarios or usecases are covered:

- *Observation-based learning*, in which the network structure is pertinent to the observations and consequently, estimates (i.e. class probabilities) are associated to the observations; in the estimation process, relational structures can either make use the training data (in-graph learning) or not (out-of-graph learning). For example, in the case of document classifcation, an observation would correspond to a publication that has to be classified into an arbitrary category, given a representation of its local content-based information as well on the its relational information (links to other documents, citations etc.).  

- *Entity-based learning*, in which observations are pertinent to one or more abstract entities for which estimates are calculated. In entity-based network learning, observations can modify either the local or relational information of one or more entities.



## Features
- **Learner type**
	- observation-based
	- entity-based

- **Relational learners**
	- simple relational neighbour
	- weighted/probabilistic relational neighbour
	- naive bayes
	- class distribution

- **Collective inference**
	- relaxation labeling
	- collective classification
	- gibbs sampling (EXPERIMENTAL, slow)

- **Adjacency strucures**
	- matrices
	- graphs
	- tuples containing functions and data from which adjacency matrices or graphs can be computed



## Observation-based network learning example

```julia
import DecisionTree
using NetworkLearning, MLDataPattern, MLLabelUtils, LossFunctions

# Download the CORA dataset, and return data and citing/cited papers indices (relative to order in X,y)
(X,y), cited_papers, citing_papers = NetworkLearning.grab_cora_data()
n = nobs(X)
yᵤ = sort(unique(y))
C = length(yᵤ)

# Split data
idx = collect(1:n);
shuffle!(idx)
p = 0.5
idxtr,idxts = splitobs(idx,p)
Xtr = X[:,idxtr]
ytr = y[idxtr]
Xts = X[:,idxts]

# Build adjacency matrices
Atr = NetworkLearning.generate_partial_adjacency(cited_papers, citing_papers, idxtr);

# Construct necessary arguments for training the network learner
fl_train = (X::Tuple{Matrix{Float64}, Vector{Int}})->  DecisionTree.build_tree(X[2],X[1]')
fl_exec(C) = (m,X)-> DecisionTree.apply_tree_proba(m, X', collect(1:C))'

fr_train = (X)->  DecisionTree.build_tree(X[2],X[1]')
fr_exec(C) = (m,X)-> DecisionTree.apply_tree_proba(m, X', collect(1:C))'

AV = [adjacency(Atr)]

# Train
info("Training ...")
nlmodel = NetworkLearning.fit(NetworkLearnerObs, 
	      Xtr,
	      ytr,
	      AV,
	      fl_train, fl_exec(C),
	      fr_train, fr_exec(C);
	      learner = :wrn,
	      inference = :ic,
	      use_local_data = false, # use only relational variables
	      f_targets = x->targets(indmax,x),
	      normalize = true,
	      maxiter = 10,
	      α = 0.95
	  )



#########################
# Out-of-Graph learning #
#########################

# Add adjacency pertinent to the test data
Ats = NetworkLearning.generate_partial_adjacency(cited_papers, citing_papers, idxts);
add_adjacency!(nlmodel, [Ats])

# Make predictions
info("Predicting (out-of-graph) ...")
ŷts = predict(nlmodel, Xts)

# Squared loss
yts = convertlabel(LabelEnc.OneOfK(C), y[idxts], yᵤ)
println("\tL2 loss (out-of-graph):", value(L2DistLoss(), yts, ŷts, AvgMode.Mean()))
println("\tAverage error (out-of-graph):", mean(targets(indmax,yts).!=targets(indmax,ŷts)))



#####################
# In-Graph learning #
#####################

# Initialize output structure
Xo = zeros(C,nobs(X))
Xo[:,idxtr] = convertlabel(LabelEnc.OneOfK(C), y[idxtr] ,yᵤ)

# Add adjacency pertinent to the test data
Ats = NetworkLearning.generate_partial_adjacency(cited_papers, citing_papers, collect(1:nobs(X)));
add_adjacency!(nlmodel, [Ats])

# Make predictions
info("Predicting (in-graph) ...")
update_mask = trues(nobs(X));
update_mask[idxtr] = false # estimates for training samples will not be used
predict!(Xo, nlmodel, X, update_mask)

# Squared loss
ŷts = Xo[:,idxts]
yts = convertlabel(LabelEnc.OneOfK(C), y[idxts], yᵤ)
println("\tL2 loss (in-graph):", value(L2DistLoss(), yts, ŷts, AvgMode.Mean()))
println("\tAverage error (in-graph):", mean(targets(indmax,yts).!=targets(indmax,ŷts)))
```

The output of the above code is:
```julia
#   % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
#                                  Dload  Upload   Total   Spent    Left  Speed
# 100  163k  100  163k    0     0   163k      0  0:00:01  0:00:01 --:--:-- 86695
# cora/
# cora/README
# cora/cora.content
# cora/cora.cites
# INFO: Training ...
# INFO: Predicting (out-of-graph) ...
# 	  L2 loss (out-of-graph):0.13011389156615571
# 	  Average error (out-of-graph):0.5310192023633677
# INFO: Predicting (in-graph) ...
# 	  L2 loss (in-graph):0.06473003424857691
#	  Average error (in-graph):0.24963072378138848
```



## Entity-based network learning example

```julia
import DecisionTree
using NetworkLearning, MLDataPattern, MLLabelUtils, LossFunctions

# Download the CORA dataset, and return data and citing/cited papers indices (relative to order in X,y)
(X,y), cited_papers, citing_papers = NetworkLearning.grab_cora_data()
n = nobs(X)
yᵤ = sort(unique(y))
C = length(yᵤ)

# Split data
idx = collect(1:n);
shuffle!(idx)
p = 0.5
idxtr,idxts = splitobs(idx,p)

### !!! ###### 	
sort!(idxtr) # It is important to sort the indices, 
sort!(idxts) # because of the use of the update mask
### !!! ######

Xtr = X[:,idxtr]
ytr = y[idxtr]
Xts = X[:,idxts]


############### Remove 70% of the citations to papers in the test data ################## 	
removed_citations = Vector{Int}()							#
for (i, (ic,oc)) in enumerate(zip(cited_papers,citing_papers))				#
	if ic in idxts && rand() > 0.3 							#
		push!(removed_citations, i)						#	
	end										#
end											#
											#
cited_incomplete = cited_papers[setdiff(1:nobs(cited_papers), removed_citations)]	#
citing_incomplete = citing_papers[setdiff(1:nobs(citing_papers), removed_citations)]	#
											#
cited_removed = cited_papers[removed_citations]						#
citing_removed = citing_papers[removed_citations]					#
#########################################################################################


# Construct adjacencies, local model, etc
Am = sparse(NetworkLearning.generate_partial_adjacency(cited_incomplete, citing_incomplete, collect(1:n)));
AV = [adjacency(Am)]
Ml = DecisionTree.build_tree(ytr,Xtr')

# Initialize output estimates and update mask
Xo = zeros(C,n)
update = falses(n);
update[idx[findin(idx,idxts)]] = true # mark only test entities i.e. unknown as updateable
Xo[:,.!update] = convertlabel(LabelEnc.OneOfK(C), ytr ,yᵤ)
Xo[:,update] = DecisionTree.apply_tree_proba(Ml, Xts', yᵤ)'
ŷ_tree = copy(Xo[:, update])

# Construct necessary arguments for training the entity network learner
fr_train = (X)->  DecisionTree.build_tree(X[2],X[1]')
fr_exec(C) = (m,X)-> DecisionTree.apply_tree_proba(m, X', collect(1:C))'


# Train
info("Training ...")
nlmodel = NetworkLearning.fit(NetworkLearnerEnt, 
	      Xo,
	      update,
	      AV,
	      fr_train, fr_exec(C);
	      learner = :wrn,
	      inference = :ic,
	      f_targets = x->targets(indmax,x),
	      normalize = true,
	      maxiter = 10,
	      α = 0.95
	  )


# Squared loss (with just a few citations)
ŷts = nlmodel.state.ê[:,update]
yts = convertlabel(LabelEnc.OneOfK(C), y[idxts], yᵤ)
println("\tL2 loss (few citations):", value(L2DistLoss(), yts, ŷts, AvgMode.Mean()))
println("\tAverage error (few citations):", mean(targets(indmax,yts).!=targets(indmax,ŷts)))

# Add citations (i.e. update adjacency matrices of the model)

# Function that updates an adjacency matrix given two vectors (of same length)
# of cited and citing paper; the function may be more complicated depending on
# how easy the corresponding adjacency matrix coordinates can be determined
# from the input data
function add_citations!(Am, cited, citing)
	for i in 1:nobs(cited)
		Am[cited[i],citing[i]] += 1
		Am[citing[i],cited[i]] += 1
	end
	return Am
end

info("Updating adjacencies ...")
f_update(ic,oc) = x->add_citations!(x, ic, oc)
update_adjacency!(nlmodel.Adj[1], f_update(cited_removed, citing_removed))

# Run again collective inference
info("Re-running collective inference ...")
infer!(nlmodel)

# Squared loss (with all citations)
ŷts = nlmodel.state.ê[:,update]
yts = convertlabel(LabelEnc.OneOfK(C), y[idxts], yᵤ)
println("\tL2 loss (all citations):", value(L2DistLoss(), yts, ŷts, AvgMode.Mean()))
println("\tAverage error (all citations):", mean(targets(indmax,yts).!=targets(indmax,ŷts)))
```

The output of the above code is:
```julia
#   % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
#                                  Dload  Upload   Total   Spent    Left  Speed
# 100  163k  100  163k    0     0   163k      0  0:00:01  0:00:01 --:--:-- 86382
# cora/
# cora/README
# cora/cora.content
# cora/cora.cites
# INFO: Training ...
# 	  L2 loss (few citations):0.061311528508626575
#	  Average error (few citations):0.27843426883308714
# INFO: Updating adjacencies ...
# INFO: Re-running collective inference ...
#	  L2 loss (all citations):0.04990883428571481
#	  Average error (all citations):0.2119645494830133
```



## Documentation

The documentation is provided in Julia's native docsystem. 



## Installation

The package can be installed by running `Pkg.add("NetworkLearning")` or, to check out the latest version,
`Pkg.checkout("NetworkLearning.jl")` in the Julia REPL. From `v0.1.0`, only versions of Julia above 0.7 
are supported. Julia v.0.6 support can be found in the `support_julia_v0.6` branch (currently unmantained).



## License

This code has an MIT license and therefore it is free.



## References
[1] S.A. Macskassy, F. Provost "Classification in networked data: A toolkit and a univariate case study", Journal of Machine learning Research 8, 2007, 935-983

[2] P. Sen, G. Namata, M. Bilgic, L. Getoor, B. Gallagher, T. Eliassi-Rad "Collective classification in network data", AI Magazine 29(3), 2008
