mutable struct WordVectors{S<:AbstractString, T<:Real, H<:Integer}
    vocab::Vector{S} # vocabulary
    vectors::Array{T, 2} # the vectors computed from GloVe
    vocab_hash::Dict{S, H}
end

function WordVectors(vocab::AbstractArray{S,1},
                     vectors::AbstractArray{T,2}) where {S<: AbstractString, T<:Real}
    length(vocab) == size(vectors, 2) ||
        throw(DimensionMismatch("Dimension of vocab and vectors are inconsistent."))
    vocab_hash = Dict{S, Int}()
    for (i, word) in enumerate(vocab)
        vocab_hash[word] = i
    end
    WordVectors(vocab, vectors, vocab_hash)
end


function Base.show(io::IO, wv::WordVectors{S,T}) where {S,T}
    len_vecs, num_words = size(wv.vectors)
    print(io, "WordVectors $(num_words) words, $(len_vecs)-element $(T) vectors")
end


"""
    vocabulary(wv)

Return the vocabulary as a vector of words of the WordVectors `wv`.
"""
vocabulary(wv::WordVectors) = wv.vocab


"""
    in_vocabulary(wv, word)

Return `true` if `word` is part of the vocabulary of the WordVector `wv` and
`false` otherwise.
"""
in_vocabulary(wv::WordVectors, word::AbstractString) = word in wv.vocab


"""
    size(wv)

Return the word vector length and the number of words as a tuple.
"""
size(wv::WordVectors) = size(wv.vectors)


"""
    index(wv, word)

Return the index of `word` from the WordVectors `wv`.
"""
index(wv::WordVectors, word) = wv.vocab_hash[word]


"""
    get_vector(wv, word [; oov=false, oov_key="<unk>")

Returns the vector representation of `word` from the WordVectors `wv`.
If `oov` is `true`, the vector corresponding to the key `oov_key` is
returned for out-of-vocabulary words.
"""
get_vector(wv::WordVectors,
           word;
           oov::Bool=false,
           oov_key::String="<unk>") = begin
    if !oov
        idx = wv.vocab_hash[word];
        return wv.vectors[:, idx]
    else
        idx = get(wv.vocab_hash, word, wv.vocab_hash[oov_key])
        return wv.vectors[:, idx]
    end
end


"""
    cosine(wv, word, n=10)

Return the position of `n` (by default `n = 10`) neighbors of `word` and their
cosine similarities.
"""
function cosine(wv::WordVectors, word, n=10)
    metrics = wv.vectors'*get_vector(wv, word)
    topn_positions = sortperm(metrics[:], rev = true)[1:n]
    topn_metrics = metrics[topn_positions]
    return topn_positions, topn_metrics
end


"""
    similarity(wv, word1, word2)

Return the cosine similarity value between two words `word1` and `word2`.
"""
function similarity(wv::WordVectors, word1, word2)
    return get_vector(wv, word1)'*get_vector(wv, word2)
end


"""
    cosine_similar_words(wv, word, n=10)

Return the top `n` (by default `n = 10`) most similar words to `word`
from the WordVectors `wv`.
"""
function cosine_similar_words(wv::WordVectors, word, n=10)
    indx, metr = cosine(wv, word, n)
    return vocabulary(wv)[indx]
end


"""
    analogy(wv, pos, neg, n=5)

Compute the analogy similarity between two lists of words. The positions
and the similarity values of the top `n` similar words will be returned.
For example,
`king - man + woman = queen` will be
`pos=[\"king\", \"woman\"], neg=[\"man\"]`.
"""
function analogy(wv::WordVectors{S,T,H}, pos::AbstractArray, neg::AbstractArray, n= 5
                ) where {S<:AbstractString, T<:Real, H<:Integer}
    m, n_vocab = size(wv)
    n_pos = length(pos)
    n_neg = length(neg)
    anal_vecs = Matrix{T}(undef, m, n_pos + n_neg)

    for (i, word) in enumerate(pos)
        anal_vecs[:,i] = get_vector(wv, word)
    end
    for (i, word) in enumerate(neg)
        anal_vecs[:,i+n_pos] = -get_vector(wv, word)
    end
    mean_vec = mean(anal_vecs, dims=2)
    metrics = wv.vectors'*mean_vec
    top_positions = sortperm(metrics[:], rev = true)[1:n+n_pos+n_neg]
    for word in [pos;neg]
        idx = index(wv, word)
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
    analogy_words(wv, pos, neg, n=5)

Return the top `n` words computed by analogy similarity between
positive words `pos` and negaive words `neg`. from the WordVectors `wv`.
"""
function analogy_words(wv::WordVectors, pos, neg, n=5)
    indx, metr = analogy(wv, pos, neg, n)
    return vocabulary(wv)[indx]
end


"""
    wordvectors(filename [,type=Float64][; kind=:text, header=false, normalize=true, vocabulary=nothing])

Generate a WordVectors type object from a file.

# Arguments
  * `filename::AbstractString` the embeddings file name
  * `type::Type` type of the embedding vector elements; default `Float64`

# Keyword arguments
  * `kind::Symbol` specifies whether the embeddings file is textual (`:text`)
or binary (`:binary`); default `:text`
  * `header::Union{Nothing, Bool}` in text embeddings files specifies
  whether the file contains a header i.e. number of lines, columns or not.
  If the header is `nothing`, the loader will attempt to autodetect the
  presence of a header; default `nothing`
  * `normalize:Bool` specifies whether to normalize the embedding vectors
i.e. return unit vectors; default true
  * `vocabulary::Union{Nothing, AbstractString}` path to the vocabulary
file generated with `vocab_count` (needed for binary embeddings);
default `nothing`
  * `load_bias::Bool` specifies whether to load the bias term or not
if using binary embedding files; default `false`
"""
function wordvectors(filename::AbstractString,
                     ::Type{T};
                     kind::Symbol=:text,
                     header::Union{Nothing, Bool}=nothing,
                     normalize::Bool=true,
                     vocabulary::Union{Nothing, AbstractString}=nothing,
                     load_bias::Bool=false
                    ) where T <: Real
    if kind == :binary
        vocabulary == nothing &&
            @error "A GloVe-generated vocabulary file path must be specified."
        return _from_binary(T, filename, vocabulary, load_bias, normalize)
    elseif kind == :text
        header == nothing && (header = autodetect_header(filename))
        if header
            return _from_text_header(T, filename, normalize)
        else
            return _from_text(T, filename, normalize)
        end
    else
        throw(ArgumentError("Unknown embedding file kind $(kind)"))
    end
end


"""
    autodetect_header(filename)

Function that attempts at autodetecting the presence of a header in a
GloVe embeddings file in a text format. If the function fails to detect
a header, a `false` value is returned.

Note: The function explicitly expects a text format for the embeddings.
The behaviour is undetermined for binary formats and no attempt at
detecting the file format is done.
"""
function autodetect_header(filename::AbstractString)
    open(filename) do f
        tokens1 = split(strip(readline(f)), ' ')
        tokens2 = split(strip(readline(f)), ' ')
        try
            # Attempt to parse the first line as header,
            # the second as an embedding
            @assert length(tokens1) == 2
            vocab_size = parse(Int, tokens1[1])
            vector_size = parse(Int, tokens1[2])
            vector = map(x-> parse(Float64, x), tokens2[2:end])
            @assert (vector_size == 2*(length(vector)+1) ||  # `model` is 0
                     vector_size == length(vector))          # `model` is 1 or 2
            return true
        catch
            return false
        end
    end
end


wordvectors(filename::AbstractString;
            kind::Symbol=:text,
            header::Bool=false,
            normalize::Bool=true,
            vocabulary::Union{Nothing, AbstractString}=nothing) =
    wordvectors(filename, Float64, kind=kind, header=header,
                normalize=normalize, vocabulary=vocabulary)


# Generate a WordVectors object from binary file
function _from_binary(::Type{T},
                      filename::AbstractString,
                      vocabulary::AbstractString,
                      load_bias::Bool=false,
                      normalize::Bool=true) where T<:Real
    vocab = Vector{String}(undef, 0)
    open(vocabulary) do f
        for line in eachline(f)
            word, count = split(line, ' ')
            push!(vocab, word)
        end
    end
    vocab_size = length(vocab)
    open(filename) do f
        nb = 0  # byte count
        while !eof(f)
            read(f,1)
            nb+= 1
        end
        vector_size = Int(nb / (2 * 8 * vocab_size))
        vector_mask = 1 : (vector_size - ifelse(load_bias, 0, 1))
        vectors = Matrix{T}(undef, length(vector_mask), vocab_size)
        binary_length = sizeof(Float64) * vector_size
        seekstart(f)
        for i in 1:vocab_size
            vector = reinterpret(Float64, read(f, binary_length))[vector_mask]
            if normalize
                vector = vector ./ norm(vector)  # unit vector
            end
            vectors[:,i] = T.(vector)
        end
        return WordVectors(vocab, vectors)
    end
end


# Generate a WordVectors object from text file
function _from_text_header(::Type{T},
                           filename::AbstractString,
                           normalize::Bool=true) where T<:Real
    open(filename) do f
        header = strip(readline(f))
        vocab_size, vector_size = map(x -> parse(Int, x), split(header, ' '))
        vocab = Vector{String}(undef, vocab_size+1)  # +1 for <unk> term
        vectors = Matrix{T}(undef, vector_size, vocab_size+1)
        i = 1
        for line in eachline(f)
            line = strip(line)
            parts = split(line, ' ')
            word = parts[1]
            vector = map(x-> parse(T, x), parts[2:end])
            if normalize
                vector = vector ./ norm(vector)  # unit vector
            end
            vocab[i] = word
            vectors[:, i] = vector
            i+= 1
        end
    return WordVectors(vocab, vectors)
    end
end


# Generate a WordVectors object from text file
function _from_text(::Type{T},
                    filename::AbstractString,
                    normalize::Bool=true) where T<:Real
    open(filename) do f
        vocab = Vector{String}()
        vectors = Vector{Vector{T}}()
        for (i, line) in enumerate(readlines(f))
            line = strip(line)
            parts = split(line, ' ')
            word = parts[1]
            vector = map(x-> parse(T, x), parts[2:end])
            if normalize
                vector = vector ./ norm(vector)  # unit vector
            end
            push!(vocab, word)
            push!(vectors, vector)
        end
        return WordVectors(vocab, reduce(hcat, vectors))
    end
end
