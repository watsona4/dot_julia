"""
    MultiNLI

A corpus of 433k sentence pairs for NLI.

For details, see the [MultiNLI home page](https://www.nyu.edu/projects/bowman/multinli/)
or read the [2018 paper](https://www.nyu.edu/projects/bowman/multinli/paper.pdf) "A Broad-Coverage Challenge Corpus for Sentence Understanding through Inference" by Adina Williams, NIkita Nangia, and Samuel R. Bowman.

Included data:
```julia
MultiNLI.train_tsv()
MultiNLI.train_jsonl()
MultiNLI.dev_matched_tsv()
MultiNLI.dev_matched_jsonl()
MultiNLI.dev_mismatched_tsv()
MultiNLI.dev_mismatched_jsonl()
```
"""
module MultiNLI

import ...register_data
using DataDeps: @datadep_str

multinli_file(filename) = joinpath(datadep"MultiNLI", "multinli_1.0", filename)

train_tsv()            = multinli_file("multinli_1.0_train.txt")
train_jsonl()          = multinli_file("multinli_1.0_train.jsonl")
dev_matched_tsv()      = multinli_file("multinli_1.0_dev_matched.txt")
dev_matched_jsonl()    = multinli_file("multinli_1.0_dev_matched.jsonl")
dev_mismatched_tsv()   = multinli_file("multinli_1.0_dev_mismatched.txt")
dev_mismatched_jsonl() = multinli_file("multinli_1.0_dev_mismatched.jsonl")

function __init__()
    register_data(
        "MultiNLI",
        """
        The Multi-Genre Natural Language Inference (MultiNLI) corpus
        is a crowd-sourced collection of 433k sentence pairs annotated
        with textual entailment information.

        https://www.nyu.edu/projects/bowman/multinli/

        The dataset is distributed as a 227MB zip file.

        For license details, see details the data description paper:
        https://www.nyu.edu/projects/bowman/multinli/paper.pdf
        """,
        "https://www.nyu.edu/projects/bowman/multinli/multinli_1.0.zip",
        "049f507b9e36b1fcb756cfd5aeb3b7a0cfcb84bf023793652987f7e7e0957822")
end

end # module
