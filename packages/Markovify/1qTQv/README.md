# Markovify

![](https://img.shields.io/github/license/mashape/apistatus.svg)
[![](https://img.shields.io/badge/docs-stable-brightgreen.svg)](https://eugleo.github.io/Markovify.jl/)

Simple text generation in Julia.

## Installation

You can install this package by using the Julia package manager. From the Julia REPL, type `]` to enter the Pkg REPL mode and run:

```
pkg> add Markovify
```

## Usage examples

All functions in this package are documented. You can view the documentation of the public symbols [here](https://eugleo.github.io/Markovify.jl/public/).

Let's say we want to build a simplistic [Lorem ipsum](https://cs.wikipedia.org/wiki/Lorem_ipsum) generator. We can use Markovify for that; the whole process can be split into three main steps:

1. Loading the training texts from a file (or multiple files) and splitting it into tokens.
2. Training the model on the tokens.
3. Walking through the model and generating random texts.

Let's assume we have our training files in the directory `files`, named `src1`, `src2` and `src3`.

```julia
using Markovify
using Tokenizer

# For each supplied file, make a model, and return an iterator of all such models
# This function actually performs both step 1 and step 2
function loadfiles(filenames)
    return (
        open(filename) do file
            text = read(file, String)
            # Tokenize on words (we could also tokenize on letters/lines etc.)
            # That means: split the text to sentences and then those sentences to words
            tokens = tokenize(text; on=words)
            return Model(tokens; order=1)
        end
        for filename in filenames
    )
end

# Print n sentences generated with the model
# This function performs step 3
function gensentences(model, n)
    sentences = []
    # Stop only after n sentences were generated
    # and passed through the length test
    while length(sentences) < n
        seq = walk(model)
        # Add the sentence to the array iff its length is ok
        if length(seq) > 5 && length(seq) < 15
            push!(sentences, join(seq, " "))
        end
    end
end

# Now we just put them together
FILENAMES = ["files/src1.txt", "files/src2.txt", "files/src3.txt"]
MODEL = combine(loadfiles(FILENAMES)...)
gensentences(MODEL, 4)
```

And the output is 4 lines of random sentences, similar to this example generated from three random French texts on [Project Gutenberg](http://www.gutenberg.org).

```
Mais elle exposa froidement le pria quelquun à dîner.
Les animaux guérissent quelquefois, la duchesse et les mères.
cest une fortune en souriant ses rivaux.
Mais la spécialité des hommes vraiment forts, évitait de Paris.
```

The most complicated step is 1: tokenizing. The constructor `Model` expects an array of arrays of tokens, so keep that in mind. There is also another method of `Model`, which can build a full model object from just the nodes dictionary (read more on nodes in the docs) — you can thus save the nodes of an existing model to a JSON file, for example, and restore it later.