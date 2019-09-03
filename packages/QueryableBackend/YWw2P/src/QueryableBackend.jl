module QueryableBackend

import IteratorInterfaceExtensions, TableTraits, QueryOperators

include("queryable/queryable.jl")
include("queryable/queryable_filter.jl")
include("queryable/queryable_map.jl")

include("source_queryable.jl")

end
