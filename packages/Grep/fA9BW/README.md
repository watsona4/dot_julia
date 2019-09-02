# Grep for Julia iterables/containers

## Usage

    grep(pattern)
    grep(function)
    grep(val)
    grep(val, iterable)

Return a function that greps out matches of an interable.


**Examples:**

```julia
julia> grep("1", 1:11)
3-element Array{Int64,1}:
  1
 10
 11

julia> grep(1, 1:11)
1-element Array{Int64,1}:
 1

julia> 1:10 |> grep(isodd)
5-element Array{Int64,1}:
 1
 3
 5
 7
 9

julia> ENV |> grep("LANG")
Dict{String,String} with 3 entries:
  "LANG"     => "en_CA.UTF-8"
  "LANGUAGE" => "en_CA"
  "GDM_LANG" => "en_CA"


julia> ENV |> grep(r"en_ca"i)
Dict{String,String} with 3 entries:
  "LANG"     => "en_CA.UTF-8"
  "LANGUAGE" => "en_CA"
  "GDM_LANG" => "en_CA"


```

