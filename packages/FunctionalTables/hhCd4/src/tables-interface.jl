#### Implementing the interface of Tables.jl

Tables.istable(::Type{<:FunctionalTable}) = true

Tables.rowaccess(::Type{<:FunctionalTable}) = true

Tables.rows(ft::FunctionalTable) = ft

Tables.schema(ft::FunctionalTable) =
    Tables.Schema(keys(columns(ft)), map(eltype, values(columns(ft))))

Tables.columnaccess(::Type{<:FunctionalTable}) = true

Tables.columns(ft::FunctionalTable) = map(collect, columns(ft))
