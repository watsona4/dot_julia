### Plain named array; names must exist

struct NamedArray{T, N, Td} <: AbstractNamedArray{T, N, Td}
    data::Td
    names::Tuple
    name_to_index::Tuple
    function NamedArray(data::AbstractArray{T, N}, names::Tuple{Vararg{AbstractArray, N}}) where {T, N}
        argcheck_constructor(data, names)
        name_to_index = Tuple(Dict(ks .=> vs) for (ks, vs) in zip(names, axes(data)))
        new{T, N, typeof(data)}(data, Tuple(names), name_to_index)
    end
end

names(A::NamedArray) = A.names
data(A::NamedArray) = A.data
name_to_index(A::NamedArray, dim) = A.name_to_index[dim]
unparameterized(::NamedArray) = NamedArray

function named_getindex(A::NamedArray, I′)
    value = default_named_getindex(A, I′)

    if all(iszero∘ndims, I′)
        # scalar indexing
        value
    else
        unparameterized(A)(value, getnames(A, I′))
    end
end

@define_named_to_indices NamedArray Union{Symbol, String, Tuple, Pair}
