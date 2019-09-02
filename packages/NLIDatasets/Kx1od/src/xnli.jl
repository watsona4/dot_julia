"""
    XNLI

A collection of 5,000 test and 2,500 dev pairs for the `MultiNLI` corpus.

For details, see the [2018 paper](https://www.aclweb.org/anthology/papers/D/D18/D18-1269/) "XNLI: Evaluating Cross-lingual Sentence Representations."

```julia
XNLI.dev_tsv()
XNLI.dev_jsonl()
XNLI.test_tsv()
XNLI.test_jsonl()
```
"""
module XNLI

import ...register_data
using DataDeps: @datadep_str

xnlifile(filename) = joinpath(datadep"XNLI", "XNLI-1.0", filename)

dev_tsv()    = xnlifile("xnli.dev.tsv")
dev_jsonl()  = xnlifile("xnli.dev.jsonl")
test_tsv()   = xnlifile("xnli.test.tsv")
test_jsonl() = xnlifile("xnli.test.jsonl")

function __init__()
    register_data(
        "XNLI",
        """
        The Cross-lingual Natural Language Inference (XNLI) corpus is a crowd-sourced collection of 5,000 test and 2,500 dev pairs for the `MultiNLI` corpus.
        """,
        "http://www.nyu.edu/projects/bowman/xnli/XNLI-1.0.zip",
        "4ba1d5e1afdb7161f0f23c66dc787802ccfa8a25a3ddd3b165a35e50df346ab1")
end

end
