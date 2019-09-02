"""
    format_mangal_coordinates(d::Dict{T,Any}) where {T <: AbstractString}

Returns a set of coordinates in a `GeoInterface` object, which can be a `Point`
or a `Polygon`.
"""
function format_mangal_coordinates(d::Dict{T,Any}) where {T <: AbstractString}
    point_type = d["geom"]["type"] == "Point" ? Point : Polygon
    if point_type == Polygon
        coords = [float.(x) for x in first(d["geom"]["coordinates"])]
        point_coordinates = point_type(coords)
    else
        coords = float.(d["geom"]["coordinates"])
        point_coordinates = point_type(coords...)
    end
    return point_coordinates
end

function format_mangal_response(::Type{MangalDataset}, d::Dict{T,Any}) where {T <: AbstractString}
    obj_id = d["id"]
    obj_public = d["public"]
    obj_name = d["name"]
    obj_date = isnothing(d["date"]) ? missing : DateTime(d["date"][1:19])
    obj_created = DateTime(d["created_at"][1:19])
    obj_updated = DateTime(d["updated_at"][1:19])
    obj_reference = isnothing(d["ref_id"]) ? missing : reference(d["ref_id"])
    obj_user = d["user_id"]
    obj_description = d["description"]

    return MangalDataset(obj_id, obj_public, obj_name, obj_date, obj_created,
        obj_updated, obj_reference, obj_user, obj_description
        )
end


function format_mangal_response(::Type{MangalNetwork}, d::Dict{T,Any}) where {T <: AbstractString}
    obj_id = d["id"]
    obj_public = d["public"]
    obj_name = d["name"]
    obj_date = isnothing(d["date"]) ? missing : DateTime(d["date"][1:19])
    obj_position = isnothing(d["geom"]) ? missing : format_mangal_coordinates(d)
    obj_created = DateTime(d["created_at"][1:19])
    obj_updated = DateTime(d["updated_at"][1:19])
    obj_user = isnothing(d["user_id"]) ? missing : d["user_id"]
    obj_description = d["description"]
    obj_complete = d["all_interactions"]
    obj_dataset = isnothing(d["dataset_id"]) ? missing : dataset(d["dataset_id"])

    return MangalNetwork(obj_id, obj_public, obj_name, obj_date, obj_position,
        obj_created, obj_updated, obj_user, obj_description,
        obj_complete, obj_dataset)

end

function format_mangal_response(::Type{MangalNode}, d::Dict{T,Any}) where {T <: AbstractString}

    obj_id = d["id"]
    obj_name = d["original_name"]
    obj_created = DateTime(d["created_at"][1:19])
    obj_updated = DateTime(d["updated_at"][1:19])
    obj_taxon = isnothing(d["taxonomy"]) ? missing : Mangal.format_mangal_response(MangalReferenceTaxon, d["taxonomy"])

    return MangalNode(obj_id, obj_name, obj_created, obj_updated, obj_taxon)

end

function format_mangal_response(::Type{MangalReferenceTaxon}, d::Dict{T,Any}) where {T <: AbstractString}

    obj_id = d["id"]
    obj_name = d["name"]
    obj_bold = isnothing(d["bold"]) ? missing : d["bold"]
    obj_tsn = isnothing(d["tsn"]) ? missing : d["tsn"]
    obj_ncbi = isnothing(d["ncbi"]) ? missing : d["ncbi"]
    obj_eol = isnothing(d["eol"]) ? missing : d["eol"]
    obj_gbif = isnothing(d["gbif"]) ? missing : d["gbif"]
    obj_created = DateTime(d["created_at"][1:19])
    obj_updated = DateTime(d["updated_at"][1:19])

    return MangalReferenceTaxon(obj_id, obj_name, obj_bold, obj_tsn,
        obj_ncbi, obj_eol, obj_gbif, obj_created, obj_updated)

end

function format_mangal_response(::Type{MangalInteraction}, d::Dict{T,Any}) where {T <: AbstractString}
    obj_id = d["id"]
    obj_network = network(d["network_id"])
    obj_from = node(d["node_from"])
    obj_to = node(d["node_to"])
    obj_date = isnothing(d["date"]) ? missing : DateTime(d["date"][1:19])
    obj_position = isnothing(d["geom"]) ? missing : format_mangal_coordinates(d)
    obj_directed = d["direction"] == "directed"
    obj_interaction = Symbol(d["type"])
    obj_method = d["method"]
    obj_strength = isnothing(d["value"]) ? missing : d["value"]
    obj_created = DateTime(d["created_at"][1:19])
    obj_updated = DateTime(d["updated_at"][1:19])
    obj_attribute = isnothing(d["attr_id"]) ? missing : format_mangal_response(MangalAttribute, d["attribute"])

    return MangalInteraction(obj_id, obj_network, obj_from, obj_to, obj_date, obj_position,
        obj_directed, obj_interaction, obj_method, obj_strength, obj_created, obj_updated,
        obj_attribute)

end

function format_mangal_response(::Type{MangalReference}, d::Dict{T,Any}) where {T <: AbstractString}
    obj_id = d["id"]
    obj_year = d["year"] == "NA" ? missing : parse(Int64, d["year"][1:4])
    obj_doi = isnothing(d["doi"]) ? missing : d["doi"]
    obj_jstor = isnothing(d["jstor"]) ? missing : d["jstor"]
    obj_pmid = isnothing(d["pmid"]) ? missing : d["pmid"]
    obj_bibtex = isnothing(d["bibtex"]) ? missing : d["bibtex"]
    obj_paper = isnothing(d["paper_url"]) ? missing : d["paper_url"]
    obj_data = isnothing(d["data_url"]) ? missing : d["data_url"]

    return MangalReference(obj_id, obj_year, obj_doi, obj_jstor, obj_pmid,
        obj_bibtex, obj_paper, obj_data)
end

function format_mangal_response(::Type{MangalAttribute}, d::Dict{T,Any}) where {T <: AbstractString}
    obj_id = d["id"]
    obj_name = d["name"]
    obj_description = d["description"]
    obj_unit = d["unit"]

    return MangalAttribute(obj_id, obj_name, obj_description, obj_unit)
end
