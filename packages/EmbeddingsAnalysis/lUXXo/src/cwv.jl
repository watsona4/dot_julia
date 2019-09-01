struct CompressedWordVectors{Q,U,D,T,S,H}
    vocab::Vector{S}                   # vocabulary
    vectors::QuantizedMatrix{Q,U,D,T}  # quantized vectors
    vocab_hash::Dict{S,H}              # word to vector index (column)
end


# Constructors
function CompressedWordVectors(vocab::AbstractVector{S},
                               vectors::QuantizedMatrix{Q,U,D,T}) where {Q,U,D,T,S}
    length(vocab) == size(vectors, 2) ||
        throw(DimensionMismatch("Dimension of vocab and vectors are inconsistent."))
    vocab_hash = Dict{S, Int}()
    for (i, word) in enumerate(vocab)
        vocab_hash[word] = i
    end
    CompressedWordVectors(vocab, vectors, vocab_hash)
end

function Base.show(io::IO, cwv::CompressedWordVectors{Q,U,D,T,S,H}) where {Q,U,D,T,S,H}
    len_vecs, num_words = size(cwv.vectors)
    print(io, "Compressed WordVectors $(num_words) words, $(len_vecs)-element $(T) vectors")
end


"""
    compress(wv [;kwargs...])

Compresses `wv::WordVectors` by using array quantization.

# Keyword arguments
  * `sampling_ratio::AbstractFloat` specifies the percentage of vectors to use
for quantization codebook creation
  * `k::Int` number of quantization values for a codebook
  * `m::Int` number of codebooks to use
  * `method::Symbol` specifies the array quantization method
  * `distance::PreMetric` is the distance

Other keyword arguments specific to the quantization methods can also be provided.
"""
function compress(wv::WordVectors{S,T,H};
                  sampling_ratio::AbstractFloat=DEFAULT_QUANTIZATION_SAMPLING_RATIO,
                  k::Int=DEFAULT_QUANTIZAION_K,
                  m::Int=DEFAULT_QUANTIZATION_M,
                  method::Symbol=DEFAULT_QUANTIZATION_METHOD,
                  distance::Distances.PreMetric=DEFAULT_QUANTIZATION_DISTANCE,
                  kwargs...) where {S,T,H}
    # Checks, initializations#
    @assert 0.0 < sampling_ratio <= 1.0 "The sampling ratio must be in >0 and <=1"
    _, n = size(wv)
    ns = clamp(round(Int, sampling_ratio * n), 1, n)

    # Sample vectors, build quantizer, quantize everything and return
    @debug "Building quantizer using $ns vectors..."
    svecs = wv.vectors[:, sample(1:n, ns, replace=false)]
    aq = build_quantizer(svecs, k=k, m=m, method=method, distance=distance; kwargs...)
    @debug "Quantizing $n vectors..."
    qvecs = quantize(aq, wv.vectors)
    return CompressedWordVectors(wv.vocab, qvecs)
end


"""
    vocabulary(cwv)

Return the vocabulary as a vector of words of the CompressedWordVectors `cwv`.
"""
vocabulary(cwv::CompressedWordVectors) = cwv.vocab


"""
    in_vocabulary(cwv, word)

Return `true` if `word` is part of the vocabulary of the CompressedWordVector `cwv` and
`false` otherwise.
"""
in_vocabulary(cwv::CompressedWordVectors, word::AbstractString) = word in cwv.vocab


"""
    size(cwv)

Return the word vector length and the number of words as a tuple.
"""
size(cwv::CompressedWordVectors) = size(cwv.vectors)


"""
    index(cwv, word)

Return the index of `word` from the CompressedWordVectors `cwv`.
"""
index(cwv::CompressedWordVectors, word) = cwv.vocab_hash[word]


"""
    get_vector(cwv, word)

Return the vector representation of `word` from the CompressedWordVectors `cwv`.
"""
get_vector(cwv::CompressedWordVectors, word) =
      (idx = cwv.vocab_hash[word]; cwv.vectors[:,idx])


"""
    cosine(cwv, word, n=10)

Return the position of `n` (by default `n = 10`) neighbors of `word` and their
cosine similarities.
"""
function cosine(cwv::CompressedWordVectors, word, n=10)
    metrics = cwv.vectors'*get_vector(cwv, word)
    topn_positions = sortperm(metrics[:], rev = true)[1:n]
    topn_metrics = metrics[topn_positions]
    return topn_positions, topn_metrics
end


"""
    similarity(cwv, word1, word2)

Return the cosine similarity value between two words `word1` and `word2`.
"""
function similarity(cwv::CompressedWordVectors, word1, word2)
    return get_vector(cwv, word1)'*get_vector(cwv, word2)
end


"""
    cosine_similar_words(cwv, word, n=10)

Return the top `n` (by default `n = 10`) most similar words to `word`
from the CompressedWordVectors `cwv`.
"""
function cosine_similar_words(cwv::CompressedWordVectors, word, n=10)
    indx, metr = cosine(cwv, word, n)
    return vocabulary(cwv)[indx]
end


"""
    analogy(cwv, pos, neg, n=5)

Compute the analogy similarity between two lists of words. The positions
and the similarity values of the top `n` similar words will be returned.
For example,
`king - man + woman = queen` will be
`pos=[\"king\", \"woman\"], neg=[\"man\"]`.
"""
function analogy(cwv::CompressedWordVectors{Q,U,D,T,S,H},
                 pos::AbstractArray, neg::AbstractArray, n=5
                ) where {Q,U,D,T,S,H}
    m, n_vocab = size(cwv)
    n_pos = length(pos)
    n_neg = length(neg)
    anal_vecs = Matrix{T}(undef, m, n_pos + n_neg)

    for (i, word) in enumerate(pos)
        anal_vecs[:,i] = get_vector(cwv, word)
    end
    for (i, word) in enumerate(neg)
        anal_vecs[:,i+n_pos] = -get_vector(cwv, word)
    end
    mean_vec = mean(anal_vecs, dims=2)
    metrics = cwv.vectors'*mean_vec
    top_positions = sortperm(metrics[:], rev = true)[1:n+n_pos+n_neg]
    for word in [pos;neg]
        idx = index(cwv, word)
        loc = findfirst(x->x==idx, top_positions)
        if loc != nothing
            splice!(top_positions, loc)
        end
    end
    topn_positions = top_positions[1:n]
    topn_metrics = metrics[topn_positions]
    return topn_positions, topn_metrics
end


"""
    analogy_words(cwv, pos, neg, n=5)

Return the top `n` words computed by analogy similarity between
positive words `pos` and negaive words `neg`. from the
CompressedWordVectors `cwv`.
"""
function analogy_words(cwv::CompressedWordVectors, pos, neg, n=5)
    indx, metr = analogy(cwv, pos, neg, n)
    return vocabulary(cwv)[indx]
end


"""
    compressedwordvectors(filename [,type=Float64][; kind=:text])

Generate a `CompressedWordVectors` type object from a file.

# Arguments
  * `filename::AbstractString` the embeddings file name
  * `type::Type` type of the embedding vector elements; default `Float64`

# Keyword arguments
  * `kind::Symbol` specifies whether the embeddings file is textual (`:text`)
or binary (`:binary`); default `:text`
"""
function compressedwordvectors(filename::AbstractString,
                               ::Type{T};
                               kind::Symbol=:text) where T <: Real
    if kind == :binary
        return _from_binary(T, filename)
    elseif kind == :text
        return _from_text(T, filename)
    else
        throw(ArgumentError("Unknown embedding file kind $(kind)"))
    end
end


compressedwordvectors(filename::AbstractString; kind::Symbol=:text) =
    compressedwordvectors(filename, Float64, kind=kind)


# Generate a WordVectors object from binary file
function _from_binary(::Type{T}, filename::AbstractString) where T<:Real
    open(filename) do fid
        nrows, vocab_size = map(x -> parse(Int, x), split(readline(fid), ' '))
        d, k, m = map(x -> parse(Int, x), split(readline(fid), ' '))
        _module, _val = split(readline(fid), ".")
        Q = eval(Expr(:., Symbol(_module), QuoteNode(Symbol(_val))))
        _module, _val = split(readline(fid), ".")
        D = eval(Expr(:., Symbol(_module), QuoteNode(Symbol(_val))))
        U = eval(Symbol(readline(fid)))
        T0 = eval(Symbol(readline(fid)))

        # Read vocabulary and compressed data
        vocab = Vector{String}(undef, vocab_size)
        data = zeros(U, m, vocab_size)
        binary_length = sizeof(U) * m
        for i in 1:vocab_size
            vocab[i] = strip(readuntil(fid, ' '))
            data[:,i] = collect(reinterpret(U, read(fid, binary_length)))
        end

        # Read codebooks
        cbooks = Vector{CodeBook{U,T}}(undef, m)
        codes_length = sizeof(U) * k
        codevecs_length = sizeof(T0) * k
        for i = 1:m
            codes = collect(reinterpret(U, read(fid, codes_length)))
            vectors = zeros(T, d, k)
            for j in 1:d
                vectors[j,:] = T.(reinterpret(T0, read(fid, codevecs_length)))
            end
            cbooks[i] = CodeBook(codes, vectors)
        end
        rotmat = Matrix{T}(undef, nrows, nrows)
        binary_length = sizeof(T) * nrows
        for i in 1:nrows
            rotmat[:,i] = collect(reinterpret(T, read(fid, binary_length)))
        end
        quantizer = ArrayQuantizer(Q(), (nrows, vocab_size), cbooks, k, D(), rotmat)
        qa = QuantizedArray(quantizer, data)
        return CompressedWordVectors(vocab, qa)
    end
end

# Generate a WordVectors object from text file
function _from_text(::Type{T}, filename::AbstractString) where T<:Real
    open(filename) do fid
        nrows, vocab_size = map(x -> parse(Int, x), split(readline(fid), ' '))
        d, k, m = map(x -> parse(Int, x), split(readline(fid), ' '))
        _module, _val = split(readline(fid), ".")
        Q = eval(Expr(:., Symbol(_module), QuoteNode(Symbol(_val))))
        _module, _val = split(readline(fid), ".")
        D = eval(Expr(:., Symbol(_module), QuoteNode(Symbol(_val))))
        U = eval(Symbol(readline(fid)))
        T0 = eval(Symbol(readline(fid)))

        # Read vocabulary and compressed data
        vocab = Vector{String}(undef, vocab_size)
        data = zeros(U, m, vocab_size)
        for i in 1:vocab_size
            line = readline(fid)
            parts = split(line, ' ')
            vocab[i] = parts[1]
            data[:,i] = map(x->parse(U, x), parts[2:end])
        end

        # Read codebooks
        cbooks = Vector{CodeBook{U,T}}(undef, m)
        for i = 1:m
            codes = map(x->parse(U, x), split(readline(fid),' '))
            vectors = zeros(T, d, k)
            for j in 1:d
                vectors[j,:] = map(x->parse(T, x), split(readline(fid), ' '))
            end
            cbooks[i] = CodeBook(codes, vectors)
        end
        rotmat = Matrix{T}(undef, nrows, nrows)
        for i in 1:nrows
            rotmat[:,i] = map(x->parse(T, x), split(readline(fid), ' '))
        end
        quantizer = ArrayQuantizer(Q(), (nrows, vocab_size), cbooks, k, D(), rotmat)
        qa = QuantizedArray(quantizer, data)
        return CompressedWordVectors(vocab, qa)
    end
end
