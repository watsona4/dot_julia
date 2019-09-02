"""
    SciTail

SciTail is a NLI dataset created from multiple-choice science exams and web sentences.

For details, see the [2018 paper](http://ai2-website.s3.amazonaws.com/publications/scitail-aaai-2018_cameraready.pdf) "SciTail: A Textual Entailment Dataset from Science Question Answering"
by Tushar Khot, Asish Sabharwal, and Peter Clark.

```julia
SciTail.train_tsv()
SciTail.train_jsonl()
SciTail.dev_tsv()
SciTail.dev_jsonl()
SciTail.test_tsv()
SciTail.test_jsonl()
```
"""
module SciTail

import ...register_data
using DataDeps: @datadep_str

scitail_base() = joinpath(datadep"SciTailV1.1", "SciTailV1.1")
scitail_jsonl(filename) = joinpath(scitail_base(), "snli_format", filename)
scitail_tsv(filename)   = joinpath(scitail_base(), "tsv_format", filename)

train_tsv()   = scitail_tsv("scitail_1.0_train.tsv")
train_jsonl() = scitail_jsonl("scitail_1.0_train.txt")
dev_tsv()     = scitail_tsv("scitail_1.0_dev.tsv")
dev_jsonl()   = scitail_jsonl("scitail_1.0_dev.txt")
test_tsv()    = scitail_tsv("scitail_1.0_test.tsv")
test_jsonl()  = scitail_jsonl("scitail_1.0_test.txt")

function __init__()
    register_data(
        "SciTailV1.1",
        """
        The SciTail dataset is an entailment dataset created from multiple-choice science exams and web sentences.

        See:
        http://data.allenai.org/scitail/
        """,
        "http://data.allenai.org.s3.amazonaws.com/downloads/SciTailV1.1.zip",
        "3fccd37350a94ca280b75998568df85fc2fc62843a3198d644fcbf858e6943d5")
end

end # module
