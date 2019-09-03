# Scryfall.jl
A Julia Scryfall.com Api wapper
[check out api](https://Scryfall.com) api.


| **Build Status**                                                                                |
|:-----------------------------------------------------------------------------------------------:|
|[![Build Status](https://travis-ci.org/Moelf/Scryfall.jl.svg?branch=master)](https://travis-ci.org/Moelf/Scryfall.jl)|

## Installation

The package is registered in `METADATA.jl` and can be installed with `Pkg.add`, or in `REPL` by pressing `] add Scryfall`.
```julia
julia> Pkg.add("Scryfall")
```

## Basic Usage
```julia
julia> import Scryfall

julia> Scryfall.getRaw("lightning bol")
Dict{String,Any} with 56 entries:
  "foil"             => true
  "mtgo_foil_id"     => 67197
  "purchase_uris"    => Dict{String,Any}("cardhoarder"=>"https://www.cardhoarder.com/cards/67…
  "oracle_text"      => "Lightning Bolt deals 3 damage to any target."
  "scryfall_set_uri" => "https://scryfall.com/sets/a25?utm_source=api"
  "collector_number" => "141"
  "set"              => "a25"
  "lang"             => "en"
  ...

julia> Scryfall.getImgurl("lightning bolt")
"https://img.scryfall.com/cards/normal/front/e/3/e3285e6b-3e79-4d7c-bf96-d920f973b122.jpg?1562442158"

julia> Scryfall.getImgurl("lightning bolt", setCode="PRM")
"https://img.scryfall.com/cards/normal/front/4/0/404a819c-8b9a-4527-a312-5e0df9c27be0.jpg?1562544239"
```
## To-Do
- [ ] More fuzzy search, potentially from google or somewhere
- [ ] Show all avaliable set code for a given card
