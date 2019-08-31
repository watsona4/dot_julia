# This structure allows you to wrap a value that supports multiple MIME
# show methods, and restrict the wrapped value to only support one. We use
# this in the documentation in one map case to force the use of PNG as the
# output format
struct MimeWrapper{T}
    source
end

function Base.show(io::IO, m::T, v::MimeWrapper{T}) where T
    show(io, m, v.source)
end
