module FastJet
using CxxWrap
const depsfile = joinpath(dirname(dirname(@__FILE__)), "deps", "deps.jl")
if !isfile(depsfile)
  error("$depsfile not found, CxxWrap did not build properly")
end
include(depsfile)

@wrapmodule(libfastjetwrap)

function __init__()
    @initcxx
end

export PseudoJet, JetDefinition, antikt_algorithm, ClusterSequence, inclusive_jets, sorted_by_pt, pt, px, py, pz, e, E, rap, phi, constituents
import Base: length, getindex, iterate
length(v::JetVec) = size(v)
getindex(v::JetVec, i) = at(v, convert(UInt64, i-1)) # julia starts counting at 1, c++ at 0. This is where we translate
iterate(it::JetVec) = length(it) > 0 ? (it[1], 2) : nothing
iterate(it::JetVec, i) = i <= length(it) ? (it[i], i+1) : nothing
end # module
