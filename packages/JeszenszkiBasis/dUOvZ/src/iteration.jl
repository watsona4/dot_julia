## Occupation vector iteration and array properties.

function Base.iterate(basis::AbstractSzbasis, state=1)
    state > basis.D && return nothing
    @view(basis.vectors[:, state]), state+1
end

Base.eltype(::Type{AbstractSzbasis}) = Vector{Int}
Base.length(basis::AbstractSzbasis) = basis.D

function Base.in(v::AbstractVector{Int}, basis::Szbasis)
    length(v) == basis.K && sum(v) == basis.N
end

function Base.in(v::AbstractVector{Int}, basis::RestrictedSzbasis)
    length(v) == basis.K && sum(v) == basis.N && maximum(v) <= basis.M
end
