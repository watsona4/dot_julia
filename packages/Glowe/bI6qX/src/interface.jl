"""
    vocab_count(corpus, vocab; max_vocab=100_000, min_count=10, verbose=2)

Extracts unigram counts.

# Arguments
  * `corpus::AbstractString` input corpus file path
  * `vocab::AbstractString` output vocabulary file path

# Keyword arguments
  * `verbose::Int` set verbosity: 0, 1 or 2 (default)
  * `max_vocab::Int` upper bound on vocabulary size, i.e. keep the <int> most frequent words. The minimum frequency words are randomly sampled so as to obtain an even distribution over the alphabet.
  * `min_count::Int` lower limit such that words which occur fewer than <int> times are discarded.

# Examples
```
julia> vocab_count("corpus.txt", "vocab.txt", verbose=2, max_vocab=100_000, min_count=10)
```
"""
function vocab_count(corpus::AbstractString,
                     vocab::AbstractString;
                     max_vocab::Int=100_000,
                     min_count::Int=10,
                     verbose::Int=2)
    command = joinpath(dirname(@__FILE__), "..",
                       "deps", "src", "GloVe-c", "build", "./vocab_count")
    parameters = String[]
    args = ["-max-vocab", "-min-count", "-verbose"]
    values = [max_vocab, min_count, verbose]

    for (arg, value) in zip(args, values)
        push!(parameters, arg)
        push!(parameters, string(value))
    end

    run(pipeline(pipeline(corpus, `$command $parameters`), vocab))
    return nothing
end


"""
    cooccur(corpus, vocab, cooccurrences; verbose=2, symmetric=0, window_size=15, memory=4.0, max_product=nothing, overflow_length=nothing, overflow_file="overflow", distance_weighting=1)

Calculates word-word cooccurrence statistics.

# Arguments
  * `corpus::AbstractString` input corpus file path
  * `vocab::AbstractString` input vocabulary file path (the vocabulary contains truncated unigram counts, produced by `vocab_count`)
  * `cooccurrences::AbstractString` output cooccurrences file path

# Keyword arguments
  * `verbose::Int` set verbosity: 0, 1, 2 (default) or 3
  * `symmetric::Int` if <int> = 0, only use left context; if <int> = 1 (default), use left and right
  * `window_size::Int` number of context words to the left (and to the right, if symmetric = 1); default 15
  * `memory::Float64` soft limit for memory consumption, in GB -- based on simple heuristic, so not extremely accurate; default 4.0
  * `max_product::Union{Nothing, Int}` limit the size of dense cooccurrence array by specifying the max product <int> of the frequency counts of the two cooccurring words. This value overrides that which is automatically produced by `memory`. Typically only needs adjustment for use with very large corpora
  * `overflow_length::Union{Nothing, Int}` limit to length <int> the sparse overflow array, which buffers cooccurrence data that does not fit in the dense array, before writing to disk. This value overrides that which is automatically produced by `memory`. Typically only needs adjustment for use with very large corpora
  * `overflow_file::String` filename, excluding extension, for temporary files; default "overflow"
  * `distance_weighting::Int` if <int> = 0, do not weight cooccurrence count by distance between words; if <int> = 1 (default), weight the cooccurrence count by inverse of distance between words"

# Examples
```
# It is assumed that vocab.txt exists and has been created by `vocab_count`
julia> cooccur("corpus.txt", "vocab.txt", "cooccurrences.bin", verbose=2, symmetric=0, window_size=10, memory=8.0, overflow_file="tempoverflow")
```
"""
function cooccur(corpus::AbstractString,
                 vocab::AbstractString,
                 cooccurrences::AbstractString;
                 verbose::Int=2,
                 symmetric::Int=1,
                 window_size::Int=15,
                 memory::Float64=4.0,
                 max_product::Union{Nothing, Int}=nothing,
                 overflow_length::Union{Nothing, Int}=nothing,
                 overflow_file::String="overflow",
                 distance_weighting::Int=1)
    command = joinpath(dirname(@__FILE__), "..",
                       "deps", "src", "GloVe-c", "build", "./cooccur")
    parameters = String[]
    args = ["-verbose", "-symmetric", "-window-size", "-memory",
            "-max-product", "-overflow-length", "-overflow-file",
            "-distance-weighting"]
    values = [verbose, symmetric, window_size, memory,
              max_product, overflow_length, overflow_file,
              distance_weighting]

    for (arg, value) in zip(args, values)
        if value != nothing
            push!(parameters, arg)
            push!(parameters, string(value))
        end
    end
    # Push '-vocab-file' separately
    push!(parameters, "-vocab-file")
    push!(parameters, vocab)

    run(pipeline(pipeline(corpus, `$command $parameters`), cooccurrences))
    return nothing
end


"""
    shuffle(cooccurences, shuffled; verbose=2, memory=4.0, array_size=nothing, temp_file="temp_shuffle")

Shuffles entries of word-word cooccurrence files.

# Arguments
  * `cooccurences::AbstractString` input cooccurrences file path
  * `shuffled::AbstractString` output shuffled cooccurences file path

# Keyword arguments
  * `verbose::Int` set verbosity: 0, 1, or 2 (default)
  * `memory::Float64` soft limit for memory consumption, in GB; default 4.0
  * `array_size::Union{Nothing, Int}` limit to length <int> the buffer which stores chunks of data to shuffle before writing to disk. This value overrides that which is automatically produced by `memory`
  * `temp_file`::String filename, excluding extension, for temporary files; default "temp_shuffle"

# Examples
```
# It is assumed that cooccurences.bin exists and has been created by `cooccur`
julia> shuffle("cooccurences.bin", "shuffled.bin", verbose=2, memory=8.0)
```
"""
function shuffle(cooccurrences::AbstractString,
                 shuffled::AbstractString;
                 verbose::Int=2,
                 memory::Float64=4.0,
                 array_size::Union{Nothing, Int}=nothing,
                 temp_file::String="temp_shuffle")
    command = joinpath(dirname(@__FILE__), "..",
                       "deps", "src", "GloVe-c", "build", "./shuffle")
    parameters = String[]
    args = ["-verbose", "-memory", "-array-size", "-temp-file"]
    values = [verbose, memory, array_size, temp_file]

    for (arg, value) in zip(args, values)
        if value != nothing
            push!(parameters, arg)
            push!(parameters, string(value))
        end
    end

    run(pipeline(pipeline(cooccurrences, `$command $parameters`), shuffled))
    return nothing
end


"""
    glove(shuffled, vocab, vectors="vectors"; verbose=2, write_header=0, vector_size=50, threads=8, iter=25, eta=0.05, alpha=0.75, x_max=100.0, binary=0, model=2, gradsq_file="gradsq", save_gradsq=0, checkpoint_every=0)

GloVe: Global Vectors for Word Representation, v0.2

# Arguments
  * `shuffled::AbstractString` binary input file of shuffled cooccurrence data (produced by `cooccur` and `shuffle`)
  * `vocab::AbstractString` file containing vocabulary (truncated unigram counts, produced by `vocab_count`)
  * `vectors::AbstractString` filename, excluding extension, for word vector output; default "vectors"

# Keyword arguments
  * `verbose::Int` set verbosity: 0, 1, or 2 (default)
  * `write_header::Int` if 1, write vocab_size/vector_size as first line. Do nothing if 0 (default)
  * `vector_size::Int` dimension of word vector representations (excluding bias term); default 50
  * `threads::Int` number of threads; default 8
  * `iter::Int` number of training iterations; default 25
  * `eta::Float64` initial learning rate; default 0.05
  * `alpha::Float64` parameter in exponent of weighting function; default 0.75
  * `x_max::Float64` parameter specifying cutoff in weighting function; default 100.0
  * `binary::Int` save output in binary format (0: text, 1: binary, 2: both); default 0
  * `model::Int` model for word vector output (for text output only); default 2
        0: output all data, for both word and context word vectors, including bias terms
        1: output word vectors, excluding bias terms
        2: output word vectors + context word vectors, excluding bias terms
  * `gradsq_file::String` filename, excluding extension, for squared gradient output; default "gradsq"
  * `save_gradsq::Int` save accumulated squared gradients; default 0 (off); ignored if `gradsq_file`
  * `checkpoint_every::Int` checkpoint a  model every <int> iterations; default 0 (off)

# Examples
```
# It is assumed that:
#  - shuffled.bin exists and has been created by `shuffled`
#  - vocab.txt exists and has been created by `vocab_count`
julia> glove("shuffled.bin", "vocab.txt", "vectors", gradsq_file="gradsq", verbose=2, vector_size=100, threads=16, alpha=0.75, x_max=100.0, eta=0.05, binary=2, model=2)
```
"""

#printf("./glove -input-file cooccurrence.shuf.bin -vocab-file vocab.txt -save-file vectors -gradsq-file gradsq -verbose 2 -vector-size 100 -threads 16 -alpha 0.75 -x-max 100.0 -eta 0.05 -binary 2 -model 2\n\n");
function glove(shuffled::AbstractString,
               vocab::AbstractString,
               vectors::AbstractString="vectors";
               verbose::Int=2,
               write_header::Int=0,
               vector_size::Int=50,
               threads::Int=8,
               iter::Int=25,
               eta::Float64=0.05,
               alpha::Float64=0.75,
               x_max::Float64=100.0,
               binary::Int=0,
               model::Int=2,
               gradsq_file::Union{Nothing, String}=nothing,
               save_gradsq::Int=0,
               checkpoint_every::Int=0)
    command = joinpath(dirname(@__FILE__), "..",
                       "deps", "src", "GloVe-c", "build", "./glove")
    parameters = String[]
    args = ["-verbose", "-write-header", "-vector-size", "-threads", "-iter",
            "-eta", "-alpha", "-x-max", "-binary", "-model", "-save-gradsq",
            "-checkpoint-every"]
    values = [verbose, write_header, vector_size, threads, iter,
              eta, alpha, x_max, binary, model, save_gradsq,
              checkpoint_every]

    for (arg, value) in zip(args, values)
        push!(parameters, arg)
        push!(parameters, string(value))
    end

    # Handle gradsq_file and save_gradsq
    if gradsq_file != nothing
        push!(parameters, "-gradsq-file")
        push!(parameters, string(gradsq_file))
    end
    if gradsq_file == nothing && save_gradsq != 0
        push!(parameters, "-save-gradsq")
        push!(parameters, string(save_gradsq))
        push!(parameters, "-gradsq-file")
        push!(parameters, "gradsq")
    end
    # Handle input and output arguments
    push!(parameters, "-input-file")
    push!(parameters, shuffled)
    push!(parameters, "-vocab-file")
    push!(parameters, vocab)
    push!(parameters, "-save-file")
    push!(parameters, vectors)

    run(`$command $parameters`)
    return nothing
end
