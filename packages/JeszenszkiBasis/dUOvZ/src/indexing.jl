## Occupation vector indexing.

Base.getindex(basis::AbstractSzbasis, i::Int) = @view basis.vectors[:, i]
