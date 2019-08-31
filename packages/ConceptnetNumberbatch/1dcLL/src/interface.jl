struct ConceptNet{L<:Language, K<:AbstractString, E<:Real}
    embeddings::Dict{L, Dict{K,Vector{E}}}
    width::Int
    fuzzy_words::Dict{L, Vector{K}}
end

ConceptNet(embeddings::Dict{K,Vector{E}}, width::Int) where
        {K<:AbstractString, E<:Real} =
    ConceptNet{Languages.English(), K, E}(embeddings, width, Dict(Languages.English()=>K[]))

# Aliases
const ConceptNetMulti{L,E<:Real} = ConceptNet{L, String, E}
const ConceptNetMultiCompressed{L} = ConceptNet{L, String, Int8}
const ConceptNetEnglish{E} = ConceptNet{Languages.English, String, E}



# Show methods
show(io::IO, conceptnet::ConceptNetMultiCompressed{L}) where L = begin
    nlanguages = length(conceptnet.embeddings)
    print(io, "ConceptNet{$L} (compressed): $nlanguages language(s)",
          ", $(length(conceptnet)) embeddings")
end

show(io::IO, conceptnet::ConceptNetMulti{L,E}) where {L,E} = begin
    nlanguages = length(conceptnet.embeddings)
    print(io, "ConceptNet{$L,$E}: $nlanguages language(s)",
          ", $(length(conceptnet)) embeddings")
end

show(io::IO, conceptnet::ConceptNetEnglish{E}) where E =
    print(io, "ConceptNet{English,$E}: $(length(conceptnet)) embeddings")



# Overloaded `get` method for a ConceptNet language dictionary
# Example: the embedding corresponding to "###_something" is returned for any search query
#          of two words where the first word in made out out 3 letters followed by
#          the word 'something'
function get(embeddings::Dict{K,Vector{E}},
             keyword::K,
             default::Vector{E},
             fuzzy_words::Vector{K};
             wildcard_matching::Bool=true) where
        {K<:AbstractString, E<:Real}
    if haskey(embeddings, keyword)
        # The keyword exists in the dictionary
        return embeddings[keyword]
    else
        if wildcard_matching
            # The keyword is not found; try fuzzy matching
            ω = 0.4 # weight assinged to matching a #, 1-w weight assigned to a matching letter
            L = length(keyword)
            matches = (word for word in fuzzy_words
                       if length(word) == L &&
                          occursin(Regex(replace(word,"#"=>".")), keyword))
            if isempty(matches)
                return default
            else
                best_match = ""
                max_score = 0
                for match in matches
                    l = length(replace(match,"#"=>"")) # number of letters matched
                    score = ω*(L-l)/L + (1-ω)*l/L
                    if score > max_score
                        best_match = match
                        max_score = score
                    end
                end
                return embeddings[best_match]
            end
        else
            # The keyword is not found; no fuzzy matching
            return default
        end
    end
end

function get(embeddings::Dict{K,Vector{E}},
             keywords::AbstractVector{K},
             default::Vector{E},
             fuzzy_words::Vector{K};
             wildcard_matching::Bool=true,
             n::Int=0) where
        {K<:AbstractString, E<:Real}
    p = length(keywords)
    keywords_embedded = Matrix{E}(undef, n, p)
    for i in 1:p
        keywords_embedded[:,i] = get(embeddings,
                                     keywords[i],
                                     default,
                                     fuzzy_words,
                                     wildcard_matching=wildcard_matching)
    end
    return keywords_embedded
end



# Indexing
# Generic indexing, multiple words
# Example: julia> conceptnet[Languages.English(), ["another", "word"])
getindex(conceptnet::ConceptNet{L,K,E}, language::L, words::S) where
        {L<:Language, K, E<:Real, S<:AbstractVector{<:AbstractString}} =
    get(conceptnet.embeddings[language],
        words,
        zeros(E, conceptnet.width),
        conceptnet.fuzzy_words[language],
        wildcard_matching=true,
        n=conceptnet.width)

# Generic indexing, multiple words
# Example: julia> conceptnet[:en, ["another", "word"]]
getindex(conceptnet::ConceptNet{L,K,E}, language::Symbol, words::S) where
        {L<:Language, K, E<:Real, S<:AbstractVector{<:AbstractString}} =
    conceptnet[LANGUAGES[language], words]

# Generic indexing, single word
# Example: julia> conceptnet[Languages.English(), "word"]
getindex(conceptnet::ConceptNet{L,K,E}, language::L, word::S) where
        {L<:Language, K, E<:Real, S<:AbstractString} =
    get(conceptnet.embeddings[language],
        word,
        zeros(E, conceptnet.width),
        conceptnet.fuzzy_words[language],
        wildcard_matching=true)

# Generic indexing, single word
# Example: julia> conceptnet[:en, "word"]
getindex(conceptnet::ConceptNet{L,K,E}, language::Symbol, word::S) where
        {L<:Language, K, E<:Real, S<:AbstractString} =
    conceptnet[LANGUAGES[language], word]

# Single-language indexing: conceptnet[["another", "word"]], if language==Languages.English()
getindex(conceptnet::ConceptNet{L,K,E}, words::S) where
        {L<:Languages.Language, K, E<:Real, S<:AbstractVector{<:AbstractString}} =
    conceptnet[L(), words]

# Single-language indexing: conceptnet["word"], if language==Languages.English()
getindex(conceptnet::ConceptNet{L,K,E}, word::S) where
        {L<:Languages.Language, K, E<:Real, S<:AbstractString} =
    conceptnet[L(), word]

# Index by language (returns a Dict{word=>embedding})
getindex(conceptnet::ConceptNet, language::L) where {L<:Languages.Language} =
    conceptnet.embeddings[language]

# Index by language (returns a Dict{word=>embedding})
getindex(conceptnet::ConceptNet, language::Symbol) =
    conceptnet.embeddings[LANGUAGES[language]]



# length methods
length(conceptnet::ConceptNet) = begin
    if !isempty(conceptnet.embeddings)
        return mapreduce(x->length(x[2]), +, conceptnet.embeddings)
    else
        return 0
    end
end



# size methods
size(conceptnet::ConceptNet) = (conceptnet.width, length(conceptnet))

size(conceptnet::ConceptNet, inds...) = (conceptnet.width, length(conceptnet))[inds...]



# in
function in(key::S, conceptnet::ConceptNet) where S<:AbstractString
    found = false
    for lang in keys(conceptnet.embeddings)
        if haskey(conceptnet.embeddings[lang], key)
            found = true
            break
        end
    end
    return found
end

function in(lang::L, conceptnet::ConceptNet) where L<:Languages.Language
    return haskey(conceptnet.embeddings, lang)
end



# Keys
keys(conceptnet::ConceptNet) =
    Iterators.flatten(keys(conceptnet.embeddings[lang]) for lang in keys(conceptnet.embeddings))
