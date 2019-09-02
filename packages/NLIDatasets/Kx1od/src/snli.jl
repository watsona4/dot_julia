"""
    SNLI

A corpus of 570k human-written English sentence pairs for NLI.

SNLI sentence pairs are manually labeled with labels entailment, contradiction,
and neutral.

For details, see the [SNLI home page](https://nlp.stanford.edu/projects/snli/)
or read the [2015 paper](https://nlp.stanford.edu/pubs/snli_paper.pdf) "A large annotated corpus for learning natural language inference"
by Samuel R. Bowman, Gabor Angeli, Christopher Potts, and Christopher Manning.

Included data:
```julia
SNLI.train_tsv()
SNLI.train_jsonl()
SNLI.dev_tsv()
SNLI.dev_jsonl()
SNLI.test_tsv()
SNLI.test_jsonl()
```
"""
module SNLI

import ...register_data
using DataDeps: @datadep_str

snli_file(filename) = joinpath(datadep"SNLI", "snli_1.0", filename)

train_tsv()   = snli_file("snli_1.0_train.txt")
train_jsonl() = snli_file("snli_1.0_train.jsonl")
dev_tsv()     = snli_file("snli_1.0_dev.txt")
dev_jsonl()   = snli_file("snli_1.0_dev.jsonl")
test_tsv()    = snli_file("snli_1.0_test.txt")
test_jsonl()  = snli_file("snli_1.0_test.jsonl")

function __init__()
    register_data(
        "SNLI",
        """
        The SNLI corpus (version 1.0) is a collection of 570k human-written
        English sentence pairs manually labeled for balanced classification
        with the labels entailment, contradiction, and neutral, supporting
        the task of natural language inference (NLI), also known as recognizing
        textual entailment (RTE).

        https://nlp.stanford.edu/projects/snli/

        The dataset is distributed as a 100MB zip file.

        The Stanford Natural Language Inference Corpus by The Stanford NLP Group
        is licensed under a Creative Commons Attribution-ShareAlike 4.0 International License.
        Based on a work at http://shannon.cs.illinois.edu/DenotationGraph/.
        """,
        "https://nlp.stanford.edu/projects/snli/snli_1.0.zip",
        "afb3d70a5af5d8de0d9d81e2637e0fb8c22d1235c2749d83125ca43dab0dbd3e")
end

end # module
