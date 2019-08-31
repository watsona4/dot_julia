"""
    BodyId

  Body identifiers.
"""
mutable struct BodyId
   "names from ID"
   names :: Dict{Int,Set{Symbol}}
   "ID from names"
   id :: Dict{Symbol,Int}
   function BodyId()
       new(Dict{Int,Set{Symbol}}(),Dict{Symbol,Int}())
   end
end

"""
    add!(bid,name,id)

  Add a new mapping name->id into BodyId instance bid.

Example:

```jldoctest
    using CALCEPH
    bid=CALCEPH.BodyId()
    CALCEPH.add!(bid,:tatooine,1000001)
    CALCEPH.add!(bid,:dagobah,1000002)
    CALCEPH.add!(bid,:endor,1000003)
    CALCEPH.add!(bid,:deathstar,1000004)
    CALCEPH.add!(bid,:endor_deathstar_system_barycenter,1000005)
    CALCEPH.add!(bid,:edsb,1000005)

# output

```
"""
function add!(bid::BodyId,name::Symbol,id::Int)
   if (name ∈ keys(bid.id))
      if bid.id[name] != id
         throw(CALCEPHException("Cannot map already defined identifier [$name] to a different ID [$id]"))
      else
         return
      end
   end
   if id ∉ keys(bid.names)
      bid.names[id] = Set{Symbol}()
   end
   push!(bid.names[id],name)
   bid.id[name]=id
   nothing
end
"""
    loadData!(bid,filename)

  Load mapping (body name,body ID) from file into BodyId instance bid.
  Names from the file are converted to lower case and have spaces replaced by
  underscores before being converted to symbols/interned strings.

  Example file [https://github.com/bgodard/CALCEPH.jl/blob/master/data/NaifIds.txt](https://github.com/bgodard/CALCEPH.jl/blob/master/data/NaifIds.txt)
"""
function loadData!(bid::BodyId,filename::AbstractString)
   pattern1 = r"^\s*([-+]{0,1}\d+)\s+\'(.*)\'.*$"
   pattern2 = r"[\s-]"
   f = open(filename);
   cnt=0
   for ln0 in eachline(f)
      cnt += 1
      ln1=strip(ln0)
      if length(ln1)>0
         if ln1[1] != '#'
            m = match(pattern1,ln1)
            if m === nothing
               throw(CALCEPHException("parsing line $cnt in data input file: $filename:\n$ln0"))
            end
            id = parse(Int,m.captures[1])
            name = Symbol(lowercase(replace(strip(m.captures[2]), pattern2 => "_")))
            add!(bid,name,id)
         end
      end
   end
   close(f)
   nothing
end

"""
    naifId

NAIF identification numbers

Examples:

```jldoctest
julia> using CALCEPH

julia> naifId.id[:sun]
10

julia> naifId.id[:mars]
499

julia> naifId.names[0]
Set(Symbol[:ssb, :solar_system_barycenter])

```

"""
const naifId = BodyId()
import CALCEPH
loadData!(naifId,joinpath(dirname(pathof(CALCEPH)), "..", "data", "NaifIds.txt"))

# NAIF IDs for Hyperbolic Asteroid 'Oumuamua (1I/2017 U1)
add!(naifId,:oumuamua,3788040)

# NAIF IDs for CALCEPH time ephemeris
add!(naifId,:timecenter,1000000000)
add!(naifId,:ttmtdb    ,1000000001)
add!(naifId,:tcgmtcb   ,1000000002)
