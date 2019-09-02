# NLIDatasets.jl

[![](https://img.shields.io/badge/docs-stable-blue.svg)](https://dellison.github.io/NLIDatasets.jl/stable) [![](https://img.shields.io/badge/docs-dev-blue.svg)](https://dellison.github.io/NLIDatasets.jl/dev)

[![Build Status](https://travis-ci.org/dellison/NLIDatasets.jl.svg?branch=master)](https://travis-ci.org/dellison/NLIDatasets.jl) [![codecov](https://codecov.io/gh/dellison/NLIDatasets.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/dellison/NLIDatasets.jl)

NLIDatasets.jl is a Julia package for working with Natural Language Inference datasets.

## Datasets

- [SNLI](https://nlp.stanford.edu/projects/snli/) (see [paper](https://nlp.stanford.edu/pubs/snli_paper.pdf))
- [MultiNLI](https://www.nyu.edu/projects/bowman/multinli/) (see [paper](https://www.nyu.edu/projects/bowman/multinli/paper.pdf))
- [XNLI](https://www.nyu.edu/projects/bowman/xnli/) (see [paper](https://www.aclweb.org/anthology/papers/D/D18/D18-1269/))
- [SciTail](http://data.allenai.org/scitail/) (see [paper](http://ai2-website.s3.amazonaws.com/publications/scitail-aaai-2018_cameraready.pdf))
- [HANS](https://github.com/tommccoy1/hans) (see [paper](https://www.aclweb.org/anthology/P19-1334))
- [BreakingNLI](https://github.com/BIU-NLP/Breaking_NLI) (see [paper](https://www.aclweb.org/anthology/P18-2103/))

## Usage

See the [documentation](https://dellison.github.io/NLIDatasets.jl/dev).

```julia
using NLIDatasets: SNLI
train, dev = SNLI.train_tsv(), SNLI.dev_tsv()
```
