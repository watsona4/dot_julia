# WikiText.jl

[![Build Status](https://travis-ci.org/dellison/WikiText.jl.svg?branch=master)](https://travis-ci.org/dellison/WikiText.jl) [![codecov.io](http://codecov.io/github/dellison/WikiText.jl/coverage.svg?branch=master)](http://codecov.io/github/dellison/WikiText.jl?branch=master)

## About

WikiText.jl provides an interface to the [WikiText Long Term Dependency Language Modeling dataset](https://blog.einstein.ai/the-wikitext-long-term-dependency-language-modeling-dataset/).

## Usage

WikiText exports the following 4 types, corresponding to the 4 available datasets:

* `WikiText2`
* `WikiText103,`
* `WikiText2Raw`
* `WikiText103Raw`

Wikitext also exports following 3 functions: 

* `trainfile`
* `validationfile`
* `testfile`

Downloading and unzipping the datasets will happen automatically (with your approval) when you access them for the first time, courtesy of [DataDeps.jl](https://github.com/oxinabox/DataDeps.jl).

```julia-repl
julia> ]add WikiText
julia> using WikiText
julia> corpus = WikiText2v1()
julia> trainfile(corpus)
"/path/to/wiki.train.tokens"
julia> validationfile(corpus)
"/path/to/wiki.valid.tokens"
```
