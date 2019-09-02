"""
    BreakingNLI

A dataset of 8193 premise-hypothesis sentence-pairs for NLI.

Each example is annotated to entailment, contradiction, and neutral.
The premise and the hypothesis are identical except for one
word/phrase that was replaced. This dataset is meant for testing
methods trained to solve the natural language inference task, and it
requires some lexical and world knowledge to achieve reasonable
performance on it.

For details, see the [GitHub page](https://github.com/BIU-NLP/Breaking_NLI) or read the [2018 paper](https://aclweb.org/anthology/P18-2103/).

Available data:
```julia
BreakingNLI.test_jsonl()
```
"""
module BreakingNLI

import ...register_data
using DataDeps: @datadep_str, unpack

test_jsonl() = joinpath(datadep"Breaking_NLI", "data", "dataset.jsonl")

function __init__()
    register_data(
        "Breaking_NLI",
        """
        Each example is annotated to entailment, contradiction, and neutral.
        The premise and the hypothesis are identical except for one
        word/phrase that was replaced. This dataset is meant for testing
        methods trained to solve the natural language inference task, and it
        requires some lexical and world knowledge to achieve reasonable
        performance on it.

        For details, see the [GitHub page](https://github.com/BIU-NLP/Breaking_NLI) or read the [2018 paper](https://aclweb.org/anthology/P18-2103/).

        This dataset is distributed as a

        Licensed under a Creative Commons Attribution-ShareAlike 4.0
        International License:
        https://creativecommons.org/licenses/by-sa/4.0/
        """,
        "https://github.com/BIU-NLP/Breaking_NLI/archive/8a7658c1ce6b732f4e8af3b06560f1a13b8b18b0.zip",
        "0ccf9e308245036dec52e369316b94326ef06c96729b336d0269974b0814581e",
        post_fetch_method = function (zip)
            unpack(zip)
            unpack(joinpath(datadep"Breaking_NLI",
                            "Breaking_NLI-8a7658c1ce6b732f4e8af3b06560f1a13b8b18b0",
                            "breaking_nli_dataset.zip"))
        end)
end

end # module
