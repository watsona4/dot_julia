__precompile__(true)

module TreeViews

"""
    hastreeview(x::T)::Bool

Called by a frontend to decide whether a tree view for type `T` is available.
Defaults to `false`.
"""
hastreeview(x) = false

"""
    numberofnodes(x)

Number of direct descendents.
Defaults to `fieldcount(typeof(x))`.
"""
numberofnodes(x::T) where {T} = fieldcount(T)

"""
    treelabel(io::IO, x, mime = MIME"text/plain"())

Prints `x`'s tree header to `io`.
Like with `Base.show` there are also methods with `mime::AbstractString` and no `mime` argument at all (which
falls back to `MIME"text/plain"()`). Please only overload the `treelabel(io::IO, x, mime::MIME)` form.
"""
treelabel(io::IO, x::T, mime::MIME"text/plain") where {T} = show(io, mime, T)
treelabel(io::IO, x::T, mime::AbstractString)  where {T} = treelabel(io, x, MIME(mime))
treelabel(io::IO, x::T)  where {T} = treelabel(io, x, MIME"text/plain"())

"""
    nodelabel(io::IO, x::T, i::Integer, mime::MIME"text/plain" = MIME"text/plain"())

Prints the label of `x`'s `i`-th child to `io`.
Like with `Base.show` there are also methods with `mime::AbstractString` and no `mime` argument at all (which
falls back to `MIME"text/plain"()`). Please only overload the `nodelabel(io::IO, x, i::Integer, mime::MIME)` form.
"""
function nodelabel(io::IO, x::T, i::Integer, mime::MIME"text/plain") where {T}
  show(io, mime, Text(String(fieldname(T, i))))
end
nodelabel(io::IO, x::T, i::Integer, mime::AbstractString)  where {T} = nodelabel(io, x, i, MIME(mime))
nodelabel(io::IO, x::T, i::Integer)  where {T} = nodelabel(io, x, i, MIME"text/plain"())

"""
    treenode(x::T, i::Integer)

Returns the `i`-th node of `x`, which is usually printed by the display frontend next to
the corresponding `treelabel`.
"""
treenode(x::T, i::Integer) where {T} = getfield(x, fieldname(T, i))

@deprecate(treelabel(io::IO, x::T, i::Integer, mime) where {T},
           nodelabel(io, x, i, mime))
@deprecate(treelabel(io::IO, x::T, i::Integer) where {T}, nodelabel(io, x, i))

end # module
