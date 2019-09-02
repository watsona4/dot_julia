"""
    cache(results::Vector{T}) where {T <: Union{MangalReferenceTaxon,MangalNode,MangalNetwork}}

Internally, the `Mangal` package uses a cache to store some objects that are
likely to be queried more than once. These are `MangalNode` and
`MangalReferenceTaxon`, which are called in a nested way during the querying of
*e.g.* `Interactions`. This is **not** a fancy mechanism, and it only works when
calling the nodes or backbones by their `id` (which is what the resources-hungry
functions do internally anyways).
"""
function cache(results::Vector{T}) where {T <: Union{MangalReferenceTaxon,MangalNode,MangalNetwork,MangalAttribute}}
    for result in results
        if !haskey(_MANGAL_CACHES[T], result.id)
            global _MANGAL_CACHES[T][result.id] = result
        end
    end
end

"""
    generate_base_header()

If a bearer token is present, this function will add it to the header.
"""
function generate_base_header()
    if haskey(ENV, "MANGAL_BEARER_TOKEN")
        return ["Authorization" => "bearer $(ENV["MANGAL_BEARER_TOKEN"])"]
    else
        return []
    end
end

"""
    generate_request_query(parameters::Pair...)

Takes a series of `Pairs`, and returns an URL-ready query string.
"""
function generate_request_query(parameters::Pair...)
    query = ""
    for (i, pair) in enumerate(promote(parameters...))
        i == 1 || (query *= "&")
        i == 1 && (query *= "?")
        query *= pair.first * "=" * string(pair.second)
    end
    return replace(query, " " => "+")
end

"""
    search_objects_by_query(endpoint::AbstractString, formatter::Function, query::Pair...)

In all cases, it is assumed that the functions will be wrapepd
in calls to query objects until no further objects are found.
"""
function search_objects_by_query(ReturnType::Type, query::Pair...)
    # Headers
    headers = Mangal.generate_base_header()

    # Full endpoint
    endpoint = Mangal.api_root * Mangal._MANGAL_ENDPOINTS[ReturnType]

    # Convert query parameters
    request_url = length(query) == 0 ? endpoint : endpoint*Mangal.generate_request_query(query...)

    # Perform the request
    this_request = HTTP.get(request_url, headers)
    request_body = String(this_request.body)
    request_body = replace(request_body, "" => "-") # This shouldn't be necessary anymore but...

    # Returns the collection
    parsed_json = JSON.parse.(request_body)

    # Return the formatted object(s)
    formatter = (x) -> format_mangal_response(ReturnType, x)
    return convert(Vector{ReturnType}, formatter.(parsed_json))
end

function number_of_objects(endpoint::AbstractString, query::Pair...)
    # Headers
    headers = Mangal.generate_base_header()

    # Full endpoint
    endpoint = Mangal.api_root * endpoint

    # Convert query parameters
    request_url = query == nothing ? endpoint : endpoint*Mangal.generate_request_query("count" => 1, query...)

    # Perform the request
    this_request = HTTP.get(request_url, headers)

    content_range = first(filter(head -> head.first == "Content-Range", this_request.headers))
    positions = parse.(Int64, split(content_range.second, [' ', '-', '/'])[2:end])
    range_begin = positions[1]+1
    range_stop = positions[2]+1
    range_ends = positions[3]

    return range_ends
end
