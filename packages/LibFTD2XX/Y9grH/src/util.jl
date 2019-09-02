# LibFTD2XX.jl - Utility Module
#
# By Reuben Hill 2019, Gowerlabs Ltd, reuben@gowerlabs.co.uk
#
# Copyright (c) Gowerlabs Ltd.

module Util

export ntuple2string, versionnumber


"""
    function ntuple2string(input::NTuple{N, Cchar}) where N

Convert an NTuple of Cchars (optionally null terminated) to a julia string.

# Example

```jldoctest
julia> ntuple2string(Cchar.(('h','e','l','l','o')))
"hello"

julia> ntuple2string(Cchar.(('h','e','l','l','o', '\0', 'x'))) # null terminated
"hello"
```

"""
function ntuple2string(input::NTuple{N, Cchar}) where N
  if any(input .== 0)
    endidx = findall(input .== 0)[1]-1
  elseif all(input .> 0)
    endidx = N
  else
    throw(ArgumentError("No terminator or negative values!"))
  end
  String(UInt8.([char for char in input[1:endidx]]))
end

function versionnumber(hex)
  hex <= 0x999999 || throw(DomainError("Input must be less than 0x999999"))
  patchhex = UInt8( (hex & 0x0000FF) >> 0 )
  patchhex <= 0x99 || throw(DomainError("Patch field must be less than or equal to 0x99"))
  minorhex = UInt8( (hex & 0x00FF00) >> 8 )
  minorhex <= 0x99 || throw(DomainError("Minor field must be less than or equal to 0x99"))
  majorhex = UInt8( (hex & 0xFF0000) >> 16 )
  majorhex <= 0x99 || throw(DomainError("Minor field must be less than or equal to 0x99"))
  
  patchdec = 10(patchhex >> 4) + (patchhex & 0x0F)
  minordec = 10(minorhex >> 4) + (minorhex & 0x0F)
  majordec = 10(majorhex >> 4) + (majorhex & 0x0F)
  
  VersionNumber(majordec,minordec,patchdec)
end

end # module Util