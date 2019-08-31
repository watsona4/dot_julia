
using Base.Iterators: flatten

function matstring(d::AbstractArray{D, T}) where {D, T}
    N = length(d)
    if N > 36
        mat = zeros(eltype(d), 40, D)
        for (i, a) in enumerate(flatten((1:20, N-19:N)))
            mat[i, :] .= d[a]
        end
    else
        mat = d
    end
    s = sprint(io -> show(IOContext(io, :limit=>true), MIME"text/plain"(), mat))
    s = join(split(s, '\n')[2:end], '\n')
    return s
end

function summarise(r::AbstractEmbedding)
    n_dataseries = length(r.embeddingdata.dataseries)
    embedding_type = typeof(r)
    npts = size(r.points, 2)
    summary = "$embedding_type with $npts points\n"
    return summary #join([summary, matstring(r.points)], "")
end

Base.show(io::IO, r::AbstractEmbedding) = println(io, summarise(r))
