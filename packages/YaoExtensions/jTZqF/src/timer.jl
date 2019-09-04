export gatetime, gatecount

const GROUPA = Union{ChainBlock, PutBlock, Concentrator, Diff, CachedBlock}
const GROUPB = Union{KronBlock, PauliString}
gatetime(::Val, c::GROUPA) = sum(gatetime, c |> subblocks)
gatetime(::Val, c::GROUPB) = maximum(gatetime, c |> subblocks)
#gatetime(s::Val{:Basic}, c::GROUPA) = invoke(gatetime, Tuple{Val, GROUPA}, s, c)
#gatetime(s::Val{:Basic}, c::GROUPB) = invoke(gatetime, Tuple{Val, GROUPB}, s, c)

gatetime(::Val{:Sym}, c::Union{ControlBlock, Daggered, PrimitiveBlock}) where N = Basic(Symbol(:T,occupied_locs(c) |> length))
gatetime(s::Val{:Sym}, c::Union{Add, Scale}) = throw(MethodError(gatetime, (s, c)))
gatetime(::Val{:Sym}, c::Measure) = c.collapseto isa Nothing ? Basic(:Tm) : Basic(:Tm) + Basic(:Treset)
gatetime(c::AbstractBlock) = gatetime(Val(:Sym), c)

gatecount(blk::AbstractBlock) = gatecount!(blk, Dict{Type{<:AbstractBlock}, Int}())
gatecount!(c::Union{ChainBlock, KronBlock, PauliString, PutBlock, Concentrator, Diff, CachedBlock}, storage::AbstractDict) = (gatecount!.(c |> subblocks, Ref(storage)); storage)
function gatecount!(c::RepeatedBlock, storage::AbstractDict)
    k = typeof(c.block)
    n = length(c.addrs)
    if haskey(storage, k)
        storage[k] += n
    else
        storage[k] = n
    end
    storage
end

function gatecount!(c::Union{PrimitiveBlock, Daggered, ControlBlock}, storage::AbstractDict)
    k = typeof(c)
    if haskey(storage, k)
        storage[k] += 1
    else
        storage[k] = 1
    end
    storage
end

gatecount!(c::TrivilGate, storage::AbstractDict) = storage
gatetime(::Val, d::Wait) = d.t
gatetime(::Val{:Sym}, d::Wait) = d.t
