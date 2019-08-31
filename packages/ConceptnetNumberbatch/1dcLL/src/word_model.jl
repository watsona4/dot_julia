# EXPERIMENTAL, not to be used!
# To use, uncomment the code below and add NearestNeighbors.

#=

# ngram NN-model for faster approximate string matching
# So far it is not really workable, results are bad
# An example can be found in "./scripts/test_word_model.jl"
#TODO(Corneliu) Improve quality and performance of this model

# Build model
function build_nn_model(words; ngram_size::Int=2)
    #words = collect(keys(cptnet))
    # Filter
    words = words[isascii.(words)]
    # Build ngrams
    ngrams = get_ngrams(words, ngram_size)
    # Build a ngram dictionary
    m = length(ngrams)
    n = length(words)
    ngramdict = Dict(ngrams[i]=>i for i in 1:m)
    # One-hot encode ngrams
    encmatrix = zeros(Float32, m, n)
    @inbounds for i in 1:n  # words
        _wgrams = get_ngrams(words[i], ngram_size)
        for _wg in _wgrams
            encmatrix[ngramdict[_wg], i] += 1.0
        end
    end
    # The model is the whole tuple
    return (words, ngramdict, KDTree(encmatrix, leafsize=1000), ngram_size)
end



function get_similar_words(target, words, ngramdict, model, ngram_size)
    _keys = keys(ngramdict)
    _wgrams = [wg for wg in get_ngrams(target, ngram_size) if wg in _keys]
    wordvec = zeros(Float32, length(ngramdict))
    for _wg in _wgrams
        wordvec[ngramdict[_wg]] += 1.0
    end
    return words[knn(model, wordvec, 3, true)[1]]
end



function get_ngrams(word::S, n::Int=2) where S<:AbstractString
    l = length(word)
    if l<=n
        return [word]
    else
        sz = n*div(l,n)-(n-1)
        ngrams = Vector{S}(undef, sz)
        for i in 1:sz
            ngrams[i] = word[i:i+n-1]
        end
        #push!(ngrams, word[n*div(l,n)-n+2:end])
    end
    return ngrams
end

function get_ngrams(words::Vector{S}, n::Int=2) where S<:AbstractString
    ngrams = S[]
    for word in words
        l = length(word)
        if l<=n
            push!(ngrams, word)
        else
            for i in 1:n*div(l,n)-(n-1)
                push!(ngrams, word[i:i+n-1])
            end
            #push!(ngrams, word[n*div(l,n)-n+2:end])
        end
    end
    return unique(ngrams)
end

=#
