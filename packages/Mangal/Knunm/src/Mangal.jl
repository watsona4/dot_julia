module Mangal

using HTTP
using JSON
using GeoInterface
using Dates

const web_root = "https://mangal.io/"
const api_root = web_root * "api/v2/"

# Login
include(joinpath(".", "login.jl"))

# Types
include(joinpath(".", "types.jl"))
export MangalDataset
export MangalNetwork
export MangalReferenceTaxon
export MangalNode
export MangalInteraction
export MangalReference
export MangalAttribute

# Endpoints
const _MANGAL_ENDPOINTS = Dict(
 MangalReferenceTaxon => "taxonomy",
 MangalNode => "node",
 MangalInteraction => "interaction",
 MangalNetwork => "network",
 MangalDataset => "dataset",
 MangalReference => "reference",
 MangalAttribute => "attribute"
)

#user = "user",
#trait = "trait",

# The cache!
global _MANGAL_CACHES = Dict(
    MangalNode => Dict{Int64, MangalNode}(),
    MangalReferenceTaxon => Dict{Int64, MangalReferenceTaxon}(),
    MangalNetwork => Dict{Int64, MangalNetwork}(),
    MangalAttribute => Dict{Int64, MangalAttribute}()
    )

# Response formatters
include("response_format.jl")

# Basic functions
include(joinpath(".", "basics.jl"))

# Generate code to write most of the API -- including count method
include(joinpath(".", "generators.jl"))
export nodes, node
export backbones, backbone
export datasets, dataset
export networks, network
export references, reference
export interactions, interaction

# Datasets
include(joinpath(".", "dataset.jl"))

# Networks
include(joinpath(".", "network.jl"))

# Taxonomy backbone(s)
include(joinpath(".", "backbone.jl"))

# Network nodes
include(joinpath(".", "node.jl"))

# Interactions
include(joinpath(".", "interaction.jl"))

# References
include(joinpath(".", "reference.jl"))

# Counts
include(joinpath(".", "count.jl"))

# EcologicalNetworks wrapper
import EcologicalNetworks
include(joinpath(".", "ecologicalnetworks.jl"))
export taxonize

end # module
