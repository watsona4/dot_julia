#==============
MetaPhlAn Utils
==============#
const taxlevels = Dict([
    :kingom     => 1,
    :phylum     => 2,
    :class      => 3,
    :order      => 4,
    :family     => 5,
    :genus      => 6,
    :species    => 7,
    :subspecies => 8])

"""
taxfilter!(df::DataFrame, level::Int=7; shortnames::Bool=true)

Filter a MetaPhlAn table (df) to a particular taxon level.
1 = Kingdom
2 = Phylum
3 = Class
4 = Order
5 = Family
6 = Genus
7 = Species
8 = Subspecies

If shortnames is true (default), also changes names in the first column to
remove higher order taxa
"""
function taxfilter!(taxonomic_profile::DataFrames.DataFrame, level::Int=7; shortnames::Bool=true)
    in(level, collect(1:8)) || @error "$level not a valid taxonomic level" taxlevels
    filter!(row->length(split(row[1], '|')) == level, taxonomic_profile)
    if shortnames
        matches = collect.(map(x->eachmatch(r"[kpcofgst]__(\w+)",x), taxonomic_profile[1]))
        taxonomic_profile[1] = String.([m[level].captures[1] for m in matches])
    end
    return taxonomic_profile
end

function taxfilter!(taxonomic_profile::DataFrames.DataFrame, level::Symbol; shortnames::Bool=true)
    in(level, keys(taxlevels)) || @error "$level not a valid taxonomic level" taxlevels
    taxfilter!(taxonomic_profile, taxlevels[level], shortnames=shortnames)
end


function taxfilter(taxonomic_profile::DataFrames.DataFrame, level::Int=7; shortnames::Bool=true)
    filt = deepcopy(taxonomic_profile)
    taxfilter!(filt, level, shortnames=shortnames)
    return filt
end

function taxfilter(taxonomic_profile::DataFrames.DataFrame, level::Symbol; shortnames::Bool=true)
    filt = deepcopy(taxonomic_profile)
    taxfilter!(filt, level, shortnames=shortnames)
    return filt
end
