"""
Download ConceptNetNumberbatch embeddings given a `url` and saves them
to a file pointed to by `localfile`.
"""
function download_embeddings(;url=CONCEPTNET_EN_LINK,
                             localfile=abspath("./_conceptnet_/" *
                                               split(url,"/")[end]))
    directory = join(split(localfile, "/")[1:end-1], "/")
    !isempty(directory) && !isdir(directory) && mkpath(directory)
    @info "Download ConceptNetNumberbatch to $localfile..."
    if !isfile(localfile)
        download(url, localfile)
        if isfile(localfile) return localfile end
    else
        @warn "$localfile already exists. Will not download."
        return localfile
    end
end



"""
Load the embeddings given a valid ConceptNetNumberbatch `filepath`,
lading at most `max_vocab_size` embeddings if no specific `keep_words` are
specified, filtering on `languages`.
"""
function load_embeddings(filepath::AbstractString;
                         max_vocab_size::Union{Nothing,Int}=nothing,
                         keep_words=String[],
                         languages::Union{Nothing, Languages.Language,
                                          Vector{<:Languages.Language},
                                          Symbol, Vector{Symbol}}=nothing,
                         data_type::Type{E}=Float64) where E<:Real
    if languages isa Nothing
        languages = unique(collect(values(LANGUAGES)))
    elseif languages isa Symbol
        languages = LANGUAGES[languages]
    elseif languages isa Vector{Symbol}
        languages = [LANGUAGES[lang] for lang in languages]
    end

    if any(endswith.(filepath, [".gz", ".gzip"]))
        conceptnet = _load_gz_embeddings(filepath,
                                         GzipDecompressor(),
                                         max_vocab_size,
                                         keep_words,
                                         languages=languages,
                                         data_type=data_type)
    elseif any(endswith.(filepath, [".h5", ".hdf5"]))
        conceptnet = _load_hdf5_embeddings(filepath,
                                           max_vocab_size,
                                           keep_words,
                                           languages=languages,
                                           data_type=data_type)
    else
        conceptnet = _load_gz_embeddings(filepath,
                                         Noop(),
                                         max_vocab_size,
                                         keep_words,
                                         languages=languages,
                                         data_type=data_type)
    end
    return conceptnet
end


"""
Load the ConceptNetNumberbatch embeddings from a .gz or uncompressed file.
"""
function _load_gz_embeddings(filepath::S1,
                             decompressor::TranscodingStreams.Codec,
                             max_vocab_size::Union{Nothing,Int},
                             keep_words::Vector{S2};
                             languages::Union{Nothing, Languages.Language,
                                              Vector{<:Languages.Language}
                                             }=nothing,
                         data_type::Type{E}=Float64) where
        {E<:Real, S1<:AbstractString, S2<:AbstractString}
    local lang_embs, _length::Int, _width::Int, type_lang, fuzzy_words
    type_word = String
    open(filepath, "r") do fid
        cfid = TranscodingStream(decompressor, fid)
        _length, _width = parse.(Int64, split(readline(cfid)))
        vocab_size = _get_vocab_size(_length,
                                     max_vocab_size,
                                     keep_words)
        lang_embs, languages, type_lang, english_only =
            process_language_argument(languages, type_word, data_type)
		fuzzy_words = Dict{type_lang, Vector{type_word}}()
        no_custom_words = length(keep_words)==0
        lang = :en
        cnt = 0
        for (idx, line) in enumerate(eachline(cfid))
            word, _ = _parseline(line, data_type, word_only=true)
            if !english_only
                _, _, _lang, word = split(word,"/")
                lang = Symbol(_lang)
            end
            if word in keep_words || no_custom_words
                if lang in keys(LANGUAGES) && LANGUAGES[lang] in languages  # use only languages mapped in LANGUAGES
                    _llang = LANGUAGES[lang]
                    if !haskey(lang_embs, _llang)
                        push!(lang_embs, _llang=>Dict{type_word,
                                                      Vector{data_type}}())
                        push!(fuzzy_words, _llang=>type_word[])
                    end
                    _, embedding = _parseline(line, data_type, word_only=false)
                    occursin("#", word) && push!(fuzzy_words[_llang], word)
                    push!(lang_embs[_llang], word=>embedding)
                    cnt+=1
                    if cnt > vocab_size-1
                        break
                    end
                end
            end
        end
        close(cfid)
    end
    return ConceptNet{type_lang, type_word, data_type}(lang_embs, _width, fuzzy_words)
end


"""
Load the ConceptNetNumberbatch embeddings from a HDF5 file.
"""
function _load_hdf5_embeddings(filepath::S1,
                               max_vocab_size::Union{Nothing,Int},
                               keep_words::Vector{S2};
                               languages::Union{Nothing, Languages.Language,
                                    Vector{<:Languages.Language}}=nothing,
                               data_type::Type{E}=Int8) where
        {S1<:AbstractString, S2<:AbstractString, E<:Real}
    local fuzzy_words
    type_word = String
    payload = h5open(read, filepath)["mat"]
    words = map(payload["axis1"]) do val
        _, _, lang, word = split(val, "/")
        return Symbol(lang), word
    end
    embeddings = payload["block0_values"]
    vocab_size = _get_vocab_size(length(words),
                                 max_vocab_size,
                                 keep_words)
    lang_embs, languages, type_lang, _ =
        process_language_argument(languages, type_word, E)
	fuzzy_words = Dict{type_lang, Vector{type_word}}()
    no_custom_words = length(keep_words)==0
    cnt = 0
    for (idx, (lang, word)) in enumerate(words)
        if word in keep_words || no_custom_words
            if haskey(LANGUAGES, lang) && LANGUAGES[lang] in languages  # use only languages mapped in LANGUAGES
                _llang = LANGUAGES[lang]
                if !haskey(lang_embs, _llang)
                    push!(lang_embs, _llang=>Dict{type_word, Vector{E}}())
                    push!(fuzzy_words, _llang=>type_word[])
                end
                occursin("#", word) && push!(fuzzy_words[_llang], word)
                push!(lang_embs[_llang], word=>embeddings[:,idx])
                cnt+=1
                if cnt > vocab_size-1
                    break
                end
            end
        end
    end
    return ConceptNet{type_lang, type_word, E}(lang_embs, size(embeddings,1), fuzzy_words)
end



# Function that returns some needed structures based on the languages provided
# Returns:
#   - a dictionary to store the embeddings
#   - a vector of Languages.Language (used to check whether to load embedding or not
#     while parsing)
#   - the type of the language
#   - a flag specifying whether only English is used or not
function process_language_argument(languages::Nothing,
                                   type_word::T1,
                                   type_data::T2) where {T1, T2}
    return Dict{Languages.Language, Dict{type_word, Vector{type_data}}}(),
           collect(language for language in LANGUAGES),
           Languages.Language, false
end

function process_language_argument(languages::Languages.English,
                                   type_word::T1,
                                   type_data::T2) where {T1, T2}
    return Dict{Languages.English, Dict{type_word, Vector{type_data}}}(), [languages],
           Languages.English, true
end

function process_language_argument(languages::L,
                                   type_word::T1,
                                   type_data::T2) where {L<:Languages.Language, T1, T2}
    return Dict{L, Dict{type_word, Vector{type_data}}}(), [languages], L, false
end

function process_language_argument(languages::Vector{L},
                                   type_word::T1,
                                   type_data::T2) where {L<:Languages.Language, T1, T2}
    if length(languages) == 1
        return process_language_argument(languages[1], type_word, type_data)
    else
        return Dict{L, Dict{type_word, Vector{type_data}}}(), languages, L, false
    end
end


"""
Calculate how many embeddings to retreive.
"""
function _get_vocab_size(real_vocab_size,
                         max_vocab_size=nothing,
                         keep_words=String[])

    # The real dataset cannot contain negative samples
    real_vocab_size = max(0, real_vocab_size)
    # If no maximum number of words is specified,
    # maximum size is the actual size
    if max_vocab_size == nothing
        max_vocab_size = real_vocab_size
    end
    # The maximum has to be at most the real size
    max_vocab_size = min(real_vocab_size, max_vocab_size)
    # The maximum cannot be more than the number of custom words
    # if there are custom words
    n_custom_words = length(keep_words)
    if n_custom_words > 0
        max_vocab_size = min(max_vocab_size, n_custom_words)
    end
    return max_vocab_size
end


"""
Parse a line of text from a ConceptNetNumberbatch delimited file.
"""
function _parseline(buf, data_type::Type{E}; word_only=false) where E<:Real
    bufvec = split(buf, " ")
    word = string(popfirst!(bufvec))
    if word_only
        return word, E[]
    else
        embedding = parse.(E, bufvec)
        return word, embedding
    end
end
