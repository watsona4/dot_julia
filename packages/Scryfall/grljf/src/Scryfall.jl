module Scryfall

export getOracle, getImgurl

import HTTP
import JSON

#=
"oracle_text"      => "{T}, Sacrifice Black Lotus: Add three mana of any one color."
"scryfall_set_uri" => "https://scryfall.com/sets/vma?utm_source=api"
"set"              => "vma"
"lang"             => "en"
"rarity"           => "mythic"
"colors"           => Any[]
"legalities"       => Dict{String,Any}("frontier"=>"not_legal","1v1"=>"banned","modern"=>"not_legal","penny"=>"not_legal","commander"=>"banned","standard"=>"not_legal","duel"=>"…
"name"             => "Black Lotus"
"oracle_id"        => "5089ec1a-f881-4d55-af14-5d996171203b"
"reserved"         => true
"uri"              => "https://api.scryfall.com/cards/bd8fa327-dd41-4737-8f19-2cf5eb1f7cdd"
"type_line"        => "Artifact"
"mana_cost"        => "{0}"
"id"               => "bd8fa327-dd41-4737-8f19-2cf5eb1f7cdd"
"scryfall_uri"     => "https://scryfall.com/card/vma/4/black-lotus?utm_source=api"
"rulings_uri"      => "https://api.scryfall.com/cards/bd8fa327-dd41-4737-8f19-2cf5eb1f7cdd/rulings"
"image_uris"       => Dict{String,Any}("normal"=>"https://img.scryfall.com/cards/normal/en/vma/4.jpg?1517813031","border_crop"=>"https://img.scryfall.com/cards/border_crop/en/vm…
"frame"            => "2015"
"full_art"         => false
"color_identity"   => Any[]
"reprint"          => true
"colorshifted"     => false
"digital"          => true
"multiverse_ids"   => Any[382866]
"illustration_id"  => "da62ded1-bedd-44c6-8950-ca56e691a899"
"highres_image"    => true
"cmc"              => 0.0
"set_name"         => "Vintage Masters"
"set_uri"          => "https://api.scryfall.com/sets/vma"
=#

function getRaw(fuzzyName::AbstractString;kwargs...)
    fuzzyName = HTTP.URIs.escapeuri(fuzzyName) #encode the fuzzyName for GET purpose
    kwargs = Dict(kwargs) #make keywords arguments a dictonary
    if haskey(kwargs, :setCode) #if 3-letter keyset is specified
        setCode = kwargs[:setCode]
        if length(setCode) == 3
            fuzzyRequest = HTTP.request("GET","https://api.scryfall.com/cards/named?set=$setCode&fuzzy=$fuzzyName")
        else
            fuzzyRequest = HTTP.request("GET","https://api.scryfall.com/cards/named?set=&fuzzy=$fuzzyName")
            @warn ("Length of setCode is incorrect, 3-letter only")
        end
    else #fallback to using anyset, let scryfall decide
        fuzzyRequest = HTTP.request("GET","https://api.scryfall.com/cards/named?set=&fuzzy=$fuzzyName")
    end
    cardDict = JSON.parse(String(fuzzyRequest.body)) #return a dictonary for wrapper functions to use
    #= println(cardDict["name"]) =#
    return cardDict
end

# wrapper function for getting oracle
function getOracle(fuzzyName::AbstractString; kwargs...)
    try
        result = getRaw(fuzzyName; kwargs...)["oracle_text"]
        sleep(0.1)
        return result
    catch
        @warn ("error in fetching from scryfall")
        return "No matching on scryfall"
    end
end

# wrapper function for getting imgurl, the "normal" one
function getImgurl(fuzzyName::AbstractString; kwargs...)
    try
        result = getRaw(fuzzyName; kwargs...)["image_uris"]["normal"]
        sleep(0.1)
        return result
    catch 
        @warn ("error in fetching from scryfall, may due to too many results")
        return "No matching on scryfall"
    end
end
end
