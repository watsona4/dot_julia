"""
Attribute
"""
struct MangalAttribute
    id::Int64
    name:: AbstractString
    description::AbstractString
    unit::AbstractString
end

"""
Reference
"""
struct MangalReference
    id::Int64
    year::Union{Missing,Int64}
    doi::Union{String,Missing}
    jstor::Union{String,Missing}
    pmid::Union{String,Missing}
    bibtex::Union{String,Missing}
    paper::Union{String,Missing}
    data::Union{String,Missing}
end

"""
A `MangalDataset` identifies a collection of networks, possibly containing
a single element. A dataset is identified by its `id` or `name` (both of
which are *unique*).

`name` (`AbstractString`): a unique name describing the dataset.

`public` (`Bool`): indicates whether the dataset details are available to others
than its owner.

`date` (`DateTime`): date and time at which the dataset was assembled. This can
refer to the sampling time of networks, or to the date at which the dataset was
finalized.

`reference` (`Union{Int64,Nothing}`) (*optional*): a reference to the `id` of
the `MangalReference`, or `nothing` if there is no associated reference for this
dataset.

`user` (`Int64`): `id` of the user who added the dataset to the database. This
is *not necessarily* the author of the dataset, see `reference` (and the same
field in the `MangalNetwork`) to get the actual authorship.

`description` (`AbstractString`): a free-form description of the dataset.
"""
struct MangalDataset
    id::Int64
    public::Bool
    name::AbstractString
    date::Union{DateTime,Missing}
    created::DateTime
    updated::DateTime
    reference::Union{MangalReference,Missing}
    user::Int64
    description::AbstractString
end

"""
A `MangalNetwork` is a wrapper around *nodes* (and not around interactions, for
reasons which are really not worth mentioning here, but see the documentation
for `MangalNode` for some hints).

`name` (`AbstractString`): a unique name describing the network.

`dataset` (`Int64`): the unique id of the `MangalDataset` to which the network
belongs.

`public` (`Bool`): indicates whether the network details are available to others
than its owner.

`date` (`DateTime`): date and time at which the network was sampled.

`position` (`AbstractGeometry`): the location at which the network was sampled.
This can be any sort of geospatial construct, most notably points *or* polygons.

`complete` (`Bool`): indicates whether the network was sampled completely, or is
a collection of interactions with possible gaps.

`reference` (`Union{Int64,Nothing}`) (*optional*): a reference to the `id` of
the `MangalReference`, or `nothing` if there is no associated reference for this
network.

`user` (`Int64`): `id` of the user who added the network to the database. This
is *not necessarily* the author of the network, see `reference` to get the
actual authorship.

`description` (`AbstractString`): a free-form description of the network.
"""
struct MangalNetwork
    id::Int64
    public::Bool
    name::AbstractString
    date::Union{DateTime,Missing}
    position::Union{AbstractGeometry,Missing}
    created::DateTime
    updated::DateTime
    user::Union{Int64,Missing}
    description::AbstractString
    complete::Bool
    dataset::Union{MangalDataset,Missing}
end

"""
Reference taxon (unique identifier of network nodes)
"""
struct MangalReferenceTaxon
    id::Int64
    name::AbstractString
    bold::Union{Int64,Missing}
    tsn::Union{Int64,Missing}
    ncbi::Union{Int64,Missing}
    eol::Union{Int64,Missing}
    gbif::Union{Int64,Missing}
    created::DateTime
    updated::DateTime
end

"""
Node in a network

The `taxon` field is a `MangalReferenceTaxon` object, so that one can, for
example, query the TSN identifier of a node through `object.taxon.tsn`.

This approach has been chosen because (i) names of nodes in networks can be non
unique and (ii) nodes within the same networks can refer to various taxonomic
levels. As an example, if a network has four distinct nodes identified as
`Ascariasis sp.`, they will represent four nodes in the networks, but map onto
the same `MangalReferenceTaxon` (representing the entire *Ascariasis* genus).
This approach provides a seemless representation of the same taxon across
different networks, but also of the same taxon *within* networks.
"""
struct MangalNode
    id::Int64
    name::AbstractString
    created::DateTime
    updated::DateTime
    taxon::Union{MangalReferenceTaxon,Missing}
end

"""
Interaction
"""
struct MangalInteraction
    id::Int64
    network::MangalNetwork
    from::MangalNode
    to::MangalNode
    date::Union{DateTime,Missing}
    position::Union{AbstractGeometry,Missing}
    directed::Bool
    interaction::Symbol
    method::AbstractString
    strength::Union{Number,Missing}
    created::DateTime
    updated::DateTime
    attribute::Union{Missing,MangalAttribute}
end
