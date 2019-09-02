types_names = (
    (MangalReferenceTaxon, :backbone),
    (MangalNode, :node),
    (MangalNetwork, :network),
    (MangalDataset, :dataset),
    (MangalReference, :reference),
    (MangalInteraction, :interaction),
    (MangalAttribute, :attribute)
    )

import Base.count

for mg_type_pair in types_names
    mg_type, mg_singular = mg_type_pair
    mg_plural = Symbol(string(mg_singular)*"s")
    @eval begin
        """
            count(::Type{$($mg_type)}, query::Pair...)

        Returns the number of $($mg_type) objects that match a query.
        """
        function count(::Type{$mg_type}, query::Pair...)
            return Mangal.number_of_objects(Mangal._MANGAL_ENDPOINTS[$mg_type], query...)
        end
    end
    if haskey(Mangal._MANGAL_CACHES, mg_type)
        @eval begin
            """
                $($mg_plural)(query::Pair...)

            This function will return objects of type $($mg_type) according to the query
            parameters. To accelerate future queries, the objects returned will be cached.

            To get the latest $($mg_type) records, this function can be called with no arguments.
            """
            function $mg_plural(query::Pair...)
                results = search_objects_by_query($mg_type, query...)
                Mangal.cache(results)
                return results
            end

            """
                $($mg_singular)(id::Int64)

            Returns the object of type $($mg_type) whose identifier is `id`.
            """
            function $mg_singular(id::Int64)
                if haskey(Mangal._MANGAL_CACHES[$mg_type], id)
                    return Mangal._MANGAL_CACHES[$mg_type][id]
                else
                    return first($mg_plural(Pair("id", id)))
                end
            end
        end
    else
        @eval begin
            """
                $($mg_plural)(query::Pair...)

            This function will return objects of type $($mg_type) according to the query
            parameters.

            To get the latest $($mg_type) records, this function can be called with no arguments.
            """
            function $mg_plural(query::Pair...)
                results = search_objects_by_query($mg_type, query...)
                return results
            end

            """
                $($mg_singular)(id::Int64)

            Returns the object of type $($mg_type) whose identifier is `id`.
            """
            function $mg_singular(id::Int64)
                return first($mg_plural(Pair("id", id)))
            end
        end
    end
end
