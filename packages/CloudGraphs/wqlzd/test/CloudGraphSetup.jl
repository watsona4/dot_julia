using Test
using Neo4j
using Graphs
using ProtoBuf
using JSON
using CloudGraphs
# using LibBSON
using Mongoc

import Base: convert

# Have we loaded the library?
@test isdefined(Main, :CloudGraphs) == true
@test typeof(CloudGraphs) == Module

# Testing type registration
mutable struct DataTest
  matrix::Array{Float64, 2}
  string::AbstractString #ASCIIString
  boolmatrix::Array{Int32,2}
  DataTest() = new()
  DataTest(m,s,b) = new(m,s,b)
end
mutable struct PackedDataTest
  vecmat::Vector{Float64}
  matrows::Int64
  string::AbstractString #ASCIIString
  boolvecmat::Array{Int32,1}
  boolmatrows::Int64
  PackedDataTest() = new()
  PackedDataTest(m,i1,s,b,i2) = new(m[:],i1,s,b[:],i2)
  PackedDataTest(d::DataTest) = new(d.matrix[:],
                                  size(d.matrix,1),
                                  d.string,
                                  d.boolmatrix[:],
                                  size(d.boolmatrix,1))
end

function convert(::Type{PackedDataTest}, d::DataTest) # encoder
  return PackedDataTest(d)
end
function convert(T::Type{DataTest}, d::PackedDataTest) # decoder
  r1 = d.matrows
  c1 = floor(Int,length(d.vecmat)/r1)
  M1 = reshape(d.vecmat,r1,c1)
  r2 = d.matrows
  c2 = floor(Int,length(d.boolvecmat)/r2)
  M2 = reshape(d.boolvecmat,r2,c2)
  return DataTest(M1,d.string,M2)
end

# Highly simplified packers and unpackers for testing.
function testEncodePackedType(a::DataTest)
  return PackedDataTest(a)
end
function testGetpackedtype(a::Any)
  return PackedDataTest()
end
function testDecodePackedType(a::Any, b::Any)
  return convert(DataTest, a)
end

# Defaults
if !haskey(ENV, "NEO4JUN")
    ENV["NEO4JUN"] = "neo4j"
end
if !haskey(ENV, "NEO4JPW")
    ENV["NEO4JPW"] = "marine"
end
if !haskey(ENV, "MONGOUN")
    ENV["MONGOUN"] = ""
end
if !haskey(ENV, "MONGOPW")
    ENV["MONGOPW"] = ""
end
configuration = CloudGraphs.CloudGraphConfiguration("localhost", 7474, ENV["NEO4JUN"], ENV["NEO4JPW"], "localhost", 27017, false, ENV["MONGOUN"], ENV["MONGOPW"]);
cloudGraph = connect(configuration, testEncodePackedType, testGetpackedtype, testDecodePackedType);
println("Success!");
