using Test, Bitcoin, Sockets

tests = ["rpc", "script", "tx", "CompactSizeUInt", "murmur3", "bloomfilter",  "address", "op", "helper", "network", "block"]

for t ∈ tests
  include("$(t)test.jl")
end
