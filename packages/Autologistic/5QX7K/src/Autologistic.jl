module Autologistic

using LightGraphs: Graph, SimpleGraph, nv, ne, adjacency_matrix, edges, add_edge!
using LinearAlgebra: norm, diag, triu, I
using SparseArrays: SparseMatrixCSC, sparse
using CSV: read
using Optim: optimize, Options, converged, BFGS
using Distributions: Normal, cdf
using SharedArrays: SharedArray
using Random: seed!, rand, randn
using Distributed: @distributed, workers
using Statistics: mean, std, quantile
import Base: show, getindex, setindex!, summary, size, IndexStyle, length

export
    #----- types -----
    AbstractAutologisticModel,
    AbstractPairwiseParameter,
    AbstractUnaryParameter,
    ALfit,
    ALfull,
    ALRsimple,
    ALsimple,
    FullPairwise,
    FullUnary,
    SpatialCoordinates,
    LinPredUnary,
    SimplePairwise,
    #----- enums -----
    CenteringKinds, none, expectation, onehalf,
    SamplingMethods, Gibbs, perfect_reuse_samples, perfect_reuse_seeds, perfect_read_once, perfect_bounding_chain,
    #----- functions -----
    addboot!,
    centeringterms,
    conditionalprobabilities,
    fit_ml!,
    fit_pl!,
    fullPMF,
    getparameters,
    getpairwiseparameters,
    getunaryparameters,
    loglikelihood,
    makegrid4,
    makegrid8,
    makebool,
    makecoded,
    makespatialgraph,
    marginalprobabilities,
    negpotential,
    oneboot,
    pseudolikelihood,
    sample,
    setparameters!,
    setunaryparameters!,
    setpairwiseparameters!

include("common.jl")
include("ALfit_type.jl")
include("abstractautologisticmodel_type.jl")
include("abstractunaryparameter_type.jl")
include("abstractpairwiseparameter_type.jl")
include("fullpairwise_type.jl")
include("fullunary_type.jl")
include("linpredunary_type.jl")
include("simplepairwise_type.jl")
include("ALsimple_type.jl")
include("ALfull_type.jl")
include("ALRsimple_type.jl")
include("samplers.jl")


end # module
