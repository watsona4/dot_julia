"""
    dataset(name::AbstractString)

Return a single dataset by its name.
"""
function dataset(name::AbstractString)
    return first(datasets(Pair("name", name)))
end
