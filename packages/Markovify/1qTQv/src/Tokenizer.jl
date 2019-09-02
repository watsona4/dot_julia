module Tokenizer

export tokenize,
       to_lines,
       to_sentences,
       to_letters,
       cleanup,
       words,
       letters,
       lines

"""
    tokenize(text[, on=letters])

Split `text` into SupTokens (array of arrays of tokens). An optional function
of general type `func(::Any) -> Vector{Vector{Any}}` can be provided to be used
for the tokenization.

For possible *combinators* which can be composed to obtain `func`, see:
[`to_lines`](@ref), [`to_sentences`](@ref), [`to_letters`](@ref), [`to_words`](@ref),
[`cleanup`](@ref).
"""
function tokenize(text; on=letters)
    return on(text)
end

"""
    to_lines(text::AbstractString)

Return an array of lines in `text`.
"""
function to_lines(text::AbstractString)
    return split(text, "\n")
end

"""
    to_sentences(text::AbstractString)

Return an array of sentences in `text`. The text is split along dots; the dots
remain in the strings, only the spaces after the dots are stripped.

The function tries to be as smart as possible. For example, the string
`"Channel No. 5 is a perfume."` will be treated as one sentence,
although it has two dots.
"""
function to_sentences(text::AbstractString)
    # Split on (optional) whitespace if it's preceeded by a dot
    # and if it's followed by a capital letter
    rule = r"((?<=[.])\s*(?=[A-Z]))|((?<=[?!])\s*)"
    split(text, rule; keepempty=false)
end

"""
    to_letters(tokens::Vector{<:AbstractString})

Split all of the tokens in `tokens` into individual characters.
"""
function to_letters(tokens::Vector{<:AbstractString})
    return [split(token, "") for token in tokens]
end

"""
    to_words(tokens::Vector{<:AbstractString}; keeppunctuation=true)

Split all of the tokens in `tokens` into individual words by whitespace.
If `keeppunctuation` is true, all of the special characters are preserved
(and thus "glued" to the preceding/following word).
"""
function to_words(tokens::Vector{<:AbstractString}; keeppunctuation=true)
    rule = if keeppunctuation r"\s+" else r"\W+" end
    return [split(token, rule; keepempty=false) for token in tokens]
end

"""
    cleanup(suptokens::Vector{<:Vector{<:AbstractString}}; badchars="»«\\n-_()[]{}<>–—\$=\'\"„“\r\t")

Remove all characters that are in `badchars` from all tokens in `suptokens`.
"""
function cleanup(suptokens::Vector{<:Vector{<:AbstractString}}; badchars="»«\n-_()[]{}<>–—\$=\'\"„“\r\t")
    cleanup_token(token) = filter(c -> !(c in badchars), token)

    return [
        # A list of non-empty cleaned-up tokens
        [cleanup_token(token) for token in suptoken if cleanup_token(token) != ""]
        # The list is built for every item in suptokens
        for suptoken in suptokens
    ]
end

"""
    letters = cleanup ∘ to_letters ∘ to_sentences

Composite function which splits its input into sentences, then the sentences
into letters, and then removes special characters.
"""
letters = cleanup ∘ to_letters ∘ to_sentences

"""
    lines = cleanup ∘ to_letters ∘ to_sentences

Composite function which splits its input into lines, then the line
into letters, and then removes special characters.
"""
lines = cleanup ∘ to_letters ∘ to_lines

"""
    words = cleanup ∘ to_letters ∘ to_sentences

Composite function which splits its input into sentences, then the sentences
into words, and then removes special characters. Please note that dots and
commas are not removed.
"""
words = cleanup ∘ to_words ∘ to_sentences

end
