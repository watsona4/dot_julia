"""
    write2disk(filename::AbstractString, wv::WordVectors [;kind=:binary])

Writes embeddings to disk.

# Arguments
  * `filename::AbstractString` the embeddings file name
  * `wv::WordVectors` the embeddings

# Keyword arguments
  * `kind::Symbol` specifies whether the embeddings file is textual (`:text`)
or binary (`:binary`); default `:binary`
"""
function write2disk(fid::IO, wv::WordVectors{S,T,H};
                    kind::Symbol=:binary
                   ) where {S<:AbstractString, T<:Real, H<:Integer}
    if kind == :binary
        _write2disk_binary(fid, wv)
    elseif kind == :text
        _write2disk_text(fid, wv)
    else
        throw(ErrorException("Supported values for the kind keyword"*
                             "argument are :text and :binary."))
    end

end

function write2disk(file::AbstractString, wv::WordVectors{S,T,H};
                    kind::Symbol=:binary
                   ) where {S<:AbstractString, T<:Real, H<:Integer}
    open(file, "w") do fid
        write2disk(fid, wv, kind=kind)
    end
end

function _write2disk_binary(fid::IO, wv::WordVectors{S,T,H}
                           ) where {S<:AbstractString, T<:Real, H<:Integer}
    vector_size, vocab_size = size(wv.vectors)
    println(fid, "$vocab_size $vector_size")
    for i in 1:vocab_size
        write(fid, wv.vocab[i])
        write(fid, ' ')
        write(fid, Float32.(wv.vectors[:,i]))
        write(fid, '\n')
    end
end

function _write2disk_text(fid::IO, wv::WordVectors{S,T,H}
                         ) where {S<:AbstractString, T<:Real, H<:Integer}
    vector_size, vocab_size = size(wv.vectors)
    println(fid, "$vocab_size $vector_size")
    for i in 1:vocab_size
        nstr = join(map(string, wv.vectors[:,i]), " ")
        println(fid, "$(wv.vocab[i]) $(nstr)")
    end
end


"""
    write2disk(filename::AbstractString, wv::CompressedWordVectors [;kind=:binary])

Writes compressed embeddings to disk.

# Arguments
  * `filename::AbstractString` the embeddings file name
  * `wv::CompressedWordVectors` the embeddings

# Keyword arguments
  * `kind::Symbol` specifies whether the embeddings file is textual (`:text`)
or binary (`:binary`); default `:binary`
"""
function write2disk(fid::IO, cwv::CompressedWordVectors{Q,U,D,T,S,H};
                    kind::Symbol=:binary) where {Q,U,D,T,S,H}
    if kind == :binary
        _write2disk_binary(fid, cwv)
    elseif kind == :text
        _write2disk_text(fid, cwv)
    else
        throw(ErrorException("Supported values for the kind keyword"*
                             "argument are :text and :binary."))
    end
end

function write2disk(file::AbstractString,
                    cwv::CompressedWordVectors{Q,U,D,T,S,H};
                    kind::Symbol=:binary) where {Q,U,D,T,S,H}
    open(file, "w") do fid
        write2disk(fid, cwv, kind=kind)
    end
end

function _write2disk_binary(fid::IO,
                            cwv::CompressedWordVectors{Q,U,D,T,S,H}
                           ) where {Q,U,D,T,S,H}
    # Initialize all variables needed to write
    nrows, vocab_size = cwv.vectors.quantizer.dims
    d = size(cwv.vectors.quantizer.codebooks[1].vectors, 1)
    m = length(cwv.vectors.quantizer.codebooks)
    k = cwv.vectors.quantizer.k
    quanttype_str = string(Q)
    disttype_str = string(D)
    quanteltype_str = string(U)
    origeltype_str = string(T)

    # Start writing text information
    println(fid, "$nrows $vocab_size")
    println(fid, "$d $k $m")
    println(fid, "$quanttype_str")
    println(fid, "$disttype_str")
    println(fid, "$quanteltype_str")
    println(fid, "$origeltype_str")

    # Write vocabulary and compressed vectors
    for i in 1:vocab_size
        write(fid, cwv.vocab[i])
        write(fid, ' ')
        write(fid, cwv.vectors.data[:,i])
    end

    # Write codebooks
    for i in 1:m
        write(fid, cwv.vectors.quantizer.codebooks[i].codes)
        for j in 1:d
            write(fid, cwv.vectors.quantizer.codebooks[i].vectors[j,:])
        end
    end
    for i in 1:nrows  # rotation matrix
        write(fid, cwv.vectors.quantizer.rot[:,i])
    end
end

function _write2disk_text(fid::IO,
                          cwv::CompressedWordVectors{Q,U,D,T,S,H}
                         ) where {Q,U,D,T,S,H}
    # Initialize all variables needed to write
    nrows, vocab_size = cwv.vectors.quantizer.dims
    d = size(cwv.vectors.quantizer.codebooks[1].vectors, 1)
    m = length(cwv.vectors.quantizer.codebooks)
    k = cwv.vectors.quantizer.k
    quanttype_str = string(Q)
    disttype_str = string(D)
    quanteltype_str = string(U)
    origeltype_str = string(T)

    # Start writing text information
    println(fid, "$nrows $vocab_size")
    println(fid, "$d $k $m")
    println(fid, "$quanttype_str")
    println(fid, "$disttype_str")
    println(fid, "$quanteltype_str")
    println(fid, "$origeltype_str")

    # Write vocabulary and compressed vectors
    for i in 1:vocab_size
        nstr = join(map(string, cwv.vectors.data[:,i]), " ")
        println(fid, "$(cwv.vocab[i]) $nstr")
    end

    # Write codebooks
    for i in 1:m
        nstr = join(map(string, cwv.vectors.quantizer.codebooks[i].codes), " ")
        println(fid, "$nstr")
        for j in 1:d
            nstr2 = join(map(string, cwv.vectors.quantizer.codebooks[i].vectors[j,:]), " ")
            println(fid, "$nstr2")
        end
    end
    for i in 1:nrows  # rotation matrix
        nstr = join(map(string, cwv.vectors.quantizer.rot[:,i]), " ")
        println(fid, "$nstr")
    end
end
