"""
    backbone(name::AbstractString)

Returns the backbone entry for a taxon, matched by *exact* name.
"""
function backbone(name::AbstractString)
    return first(backbones(Pair("name", name)))
end
