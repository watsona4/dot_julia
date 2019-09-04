export TextConfig, save, load, normalize_text, tokenize
using Unicode

#, language!
# using Languages
# using SnowballStemmer

# const _PUNCTUACTION = """;:,.@#&\\-\"'/:*"""
const _PUNCTUACTION = """;:,.&\\-\"'/:*“”«»"""
const _SYMBOLS = "()[]¿?¡!{}~<>|"
const PUNCTUACTION  = _PUNCTUACTION * _SYMBOLS
# A symbol s in this list will be expanded to BLANK*s if the predecesor of s is neither s nor BLANK
# On changes from s to BLANK or [^s] it will produce also produce an extra BLANK
# Note that enabled del_punc will delete all these symbols without any of the previous expansions

const BLANK_LIST = string(' ', '\t', '\n', '\v', '\r')
const RE_USER = r"""@[^;:,.@#&\\\-\"'/:\*\(\)\[\]\¿\?\¡\!\{\}~\<\>\|\s]+"""
const RE_URL = r"(http|ftp|https)://\S+"
const BLANK = ' '
const PUNCTUACTION_BLANK = string(PUNCTUACTION, BLANK)

# SKIP_WORDS = set(["…", "..", "...", "...."])

mutable struct TextConfig
    del_diac::Bool
    del_dup::Bool
    del_punc::Bool
    del_num::Bool
    del_url::Bool
    del_usr::Bool
    lc::Bool
    qlist::Vector{Int}
    nlist::Vector{Int}
    skiplist::Vector{Tuple{Int,Int}}
 
    """
    Initializes a `TextConfig` structure
    """
    function TextConfig(;
        del_diac=true,
        del_dup=false,
        del_punc=false,
        del_num=true,
        del_url=true,
        del_usr=false,
        lc=true,
        qlist=Int[],
        nlist=Int[1],
        skiplist=Tuple{Int,Int}[]
    )
        new(del_diac, del_dup, del_punc, del_num, del_url, del_usr, lc,
            qlist, nlist, skiplist)
    end
end

"""
    normalize_text(config::TextConfig, text::String)::Vector{Char}

Normalizes a given text using the specified transformations of `config`

"""
function normalize_text(config::TextConfig, text::String)::Vector{Char}
    if config.lc
        text = lowercase(text)
    end

    if config.del_url
        text = replace(text, RE_URL => "")
    end

    if config.del_usr
        text = replace(text, RE_USER => "")
    end

    L = Char[BLANK]
    prev = BLANK

    @inbounds for u in Unicode.normalize(text, :NFD)
        if config.del_diac
            o = Int(u)
            0x300 <= o && o <= 0x036F && continue
        end

        if u in BLANK_LIST
            u = BLANK
        elseif config.del_dup && prev == u
            continue
        elseif config.del_punc && u in PUNCTUACTION
            prev = u
            continue
        elseif config.del_num && isdigit(u)
            continue
        end

        prev = u
        push!(L, u)
    end

    push!(L, BLANK)

    L
end


"""
    push_word!(config::TextConfig, output::Vector{String}, token::String, normalize::Function)

Pushes a word into token list after applying the `normalize` function; it discards empty strings.
"""
function push_word!(config::TextConfig, output::Vector{Symbol}, token::Vector{UInt8}, normalize::Function)
    if length(token) > 0
        t = normalize(String(token))::String

        if length(t) > 0
            push!(output, Symbol(t))
        end
    end
end

"""
    tokenize_words(config::TextConfig, text::Vector{Char}, normalize::Function)

Performs the word tokenization
"""
function tokenize_words(config::TextConfig, text::Vector{Char}, normalize::Function, buff::IOBuffer)
    n = length(text)
    L = Symbol[]
    @inbounds for i in 1:n
        c = text[i]

        if c == BLANK
            push_word!(config, L, take!(buff), normalize)
        elseif i > 1
            if text[i-1] in PUNCTUACTION && !(c in PUNCTUACTION)
                push_word!(config, L, take!(buff), normalize)
                write(buff, c)
                continue
            elseif !(text[i-1] in PUNCTUACTION_BLANK) && c in PUNCTUACTION
                push_word!(config, L, take!(buff), normalize)
                write(buff, c)
                continue
            else
                write(buff, c)
            end
        else
            write(buff, c)
        end
    end

    push_word!(config, L, take!(buff), normalize)

    L
end

"""
    tokenize(config::TextConfig, arr::AbstractVector)::Vector{Symbol}

Tokenizes an array of strings
"""
function tokenize(config::TextConfig, arr::AbstractVector, normalize::Function=identity)::Vector{Symbol}
    L = Symbol[]
    sizehint!(L, (length(config.nlist) + length(config.skiplist)) * (div(n, 2) + 1) + length(config.qlist) * n)
    for text in arr
        t = normalize_text(config, text)
        tokenize_(config, t, L, normalize)
    end

    L
end

"""
    tokenize(config::TextConfig, text::String)::Vector{Symbol}

Tokenizes a string
"""
function tokenize(config::TextConfig, text::String, normalize::Function=identity)::Vector{Symbol}
    t = normalize_text(config, text)
    n = length(text)
    L = Symbol[]
    sizehint!(L, (length(config.nlist) + length(config.skiplist)) * (div(n, 2) + 1) + length(config.qlist) * n)
    tokenize_(config, t, L, normalize)
end


"""
    tokenize_(config::TextConfig, text::Vector{Char}, L::Vector{Symbol})::Vector{Symbol}

Tokenizes a vector of characters (internal method)
"""
function tokenize_(config::TextConfig, text::Vector{Char}, L::Vector{Symbol}, normalize::Function)::Vector{Symbol}
    n = length(text)
    buff = IOBuffer(Vector{UInt8}(undef, 64), write=true)
    @inbounds for q in config.qlist
        for i in 1:(n - q + 1)
            last = i + q - 1
            for j in i:last
                # for w in @view text[i:]
                write(buff, text[j])
            end

            push!(L, Symbol(take!(buff)))
        end
    end

    if length(config.nlist) > 0 || length(config.skiplist) > 0
        ltext = tokenize_words(config, text, normalize, buff)
        n = length(ltext)

        @inbounds for q in config.nlist
            for i in 1:(n - q + 1)
                last = i + q - 1
                for j in i:last-1
                    # for w in @view ltext[i:i+q-1]
                    write(buff, ltext[j])
                    write(buff, BLANK)
                end
                write(buff, ltext[last])
                # w = join(v, BLANK)
                # push!(L, Symbol(w))
                push!(L, Symbol(take!(buff)))
            end
        end

        @inbounds for (qsize, skip) in config.skiplist
            for start in 1:(n - (qsize + (qsize - 1) * skip) + 1)
                if qsize == 2
                    t = Symbol(ltext[start], BLANK, ltext[start + 1 + skip])
                else
                    t = Symbol(join([ltext[start + i * (1+skip)] for i in 0:(qsize-1)], BLANK))
                end
                
                push!(L, t)
            end
        end
    end

    L
end
