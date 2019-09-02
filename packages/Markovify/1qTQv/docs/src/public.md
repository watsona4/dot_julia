# Public Documentation

## [Module Markovify](@id pub_markov)
The following is the documentation of symbols which are exported from the `Markovify` module. The module is used to construct a Markov chain from the given list of lists of tokens and to walk through it, generating a random sequence of tokens along the way. Please see Příklady if you are looking for some usage examples.

```@autodocs
Modules = [Markovify]
Private = false
Order   = [:type, :function]
```
## [Module Markovify.Tokenizer](@id pub_tokenizer)
The following symbols are exported from the `Markovify.Tokenizer` module. This module is used to tokenize text into a list of lists of tokens, which is a format better suited for model training.

```@autodocs
Modules = [Tokenizer]
Private = false
Order   = [:type, :function]
```
