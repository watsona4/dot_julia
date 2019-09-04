[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT) [![Build Status](https://travis-ci.org/rahulkp220/Zomato.jl.svg?branch=master)](https://travis-ci.org/rahulkp220/Zomato.jl) [![GitHub contributors](https://img.shields.io/github/contributors/rahulkp220/Zomato.jl.svg)](https://github.com/rahulkp220/Zomato.jl/graphs/contributors) [![GitHub issues](https://img.shields.io/github/issues/rahulkp220/Zomato.jl.svg)](https://github.com/rahulkp220/Zomato.jl/issues/) [![GitHub version](https://badge.fury.io/gh/rahulkp220%2FZomato.jl.svg)](https://github.com/rahulkp220/Zomato.jl)

[![ForTheBadge built-with-love](http://ForTheBadge.com/images/badges/built-with-love.svg)](https://github.com/rahulkp220/)

# Zomato.jl

An unofficial Julia wrapper for Zomato's API :fire:
However, the official documentation can be reached [here](https://developers.zomato.com/documentation)

### Installation

```julia
julia> import Pkg
julia> Pkg.clone("https://github.com/rahulkp220/Zomato.jl")
```

### How it works?
As per Zomato's official guidelines, access to restaurant information and search on Zomato is limited to 1000 calls per day. Hence the limit should be kept in mind.

```julia
# authenticate
julia> auth = Zomato.authenticate("API-KEY")
Zomato(https://developers.zomato.com/api/v2.1/)

# get the categories
julia> Zomato.get(auth, CategoriesAPI)
[ Info: fetching categories...
Dict{String,Any} with 1 entry:
  "categories" => Any[Dict{String,Any}("categories"=>Dict{String,Any}("name"=>"Delivery","id"=>1)), Dict{String,Any}("categories"=>Dict{String,Any}("name"=>…

# get city wise details
julia> Zomato.get(auth, CitiesAPI, q="london")
[ Info: fetching city details...
Dict{String,Any} with 4 entries:
  "location_suggestions" => Any[Dict{String,Any}("is_state"=>0,"state_name"=>"England and Wales","name"=>"London","id"=>61,"state_code"=>"England and Wales"…
  "has_total"            => 0
  "status"               => "success"
  "has_more"             => 0
```

### Documentation

Each function has an extensive API documentation, a sample of which is given below.

```
help?>Zomato.get(z::Zomato.Auth, ::Type{Zomato.CitiesAPI}; kwargs...)
  Get city details
  ==================

  Find the Zomato ID and other details for a city . 
  You can obtain the Zomato City ID in one of the following ways:

    •    City Name in the Search Query - 
    Returns list of cities matching the query

    •    Using coordinates - 
    Identifies the city details based on the coordinates of any location inside a city

  If you already know the Zomato City ID, this API can be used to get other details of the city.

  See https://developers.zomato.com/documentation#!/common/cities

  Arguments
  ===========

  Parameter Description                      Parameter Type Data Type
  ––––––––– –––––––––––––––––––––––––––––––– –––––––––––––– –––––––––
  q         query by city name               query          String
  lat       latitude                         query          Float
  lon       longitude                        query          Float
  city_ids  comma separated city_id values   query          String
  count     number of max results to display query          Int
```

### Facing issues? :scream:
* Open a PR with the detailed expaination of the issue
* Reach me out [here](https://www.rahullakhanpal.in)
