# Setup everything using the common setup.
include("CloudGraphSetup.jl")

# And check that if we encode and decode this type, it's exactly the same.
# Make a packed data test structure.
fullType = DataTest(rand(10,10), "This is a test string", rand(Int32,10,10));
typePackedRegName = string(PackedDataTest);
typeOriginalRegName = string(DataTest);
# Now lets encode and decode to see.
println("Encoding...")
testPackedType = convert(PackedDataTest, fullType);
# testPackedType = cloudGraph.packedOriginalDataTypes[typeOriginalRegName].encodingFunction(PackedDataTest, fullType);

println("Decoding...")
testFullType = convert(DataTest, testPackedType);
# testFullType = cloudGraph.packedPackedDataTypes[typePackedRegName].decodingFunction(DataTest, testPackedType);


@test json(testFullType) == json(fullType)
println("Success!")

# Creating a local test graph.
print("[TEST] Creating a CloudVertex from an ExVertex...")
localGraph = graph(ExVertex[], ExEdge{ExVertex}[]);
#Make an ExVertex that may be encoded
v = make_vertex(localGraph, "TestVertex");
vertex = Graphs.add_vertex!(localGraph, v);
vertex.attributes["data"] = fullType;
vertex.attributes["age"] = 64;
vertex.attributes["latestEstimate"] = [0.0,0.0,0.0];
bigData = CloudGraphs.BigData();
testElementLegacy = CloudGraphs.BigDataElement("TestLegacy", "Performance test dataset legacy.", rand(UInt8,100), -1); #Data element
testElementDict = CloudGraphs.BigDataElement("TestDictSet", "Performance test dataset new dict type.", Dict{String, Any}("testString"=>"Test String", "randUint8"=>rand(UInt8,100)), -1); #Data element
# TODO: Check BigData scenarios.
# append!(bigData.dataElements, [testElementLegacy, testElementDict]);
vertex.attributes["bigData"] = bigData;
# Now encoding the structure to CloudGraphs vertex
cloudVertex = CloudGraphs.exVertex2CloudVertex(vertex);
println("Success!");

print("[TEST] Adding a vertex...")
CloudGraphs.add_vertex!(cloudGraph, cloudVertex);
println("Success!")

# Get the node from Neo4j.
print("[TEST] Retrieving a node from CloudGraph...")
cloudVertexRet = CloudGraphs.get_vertex(cloudGraph, cloudVertex.neo4jNode.id, false) # fullType not required
# Check that all the important bits match using string comparisons of the JSON form of the structures
@test json(cloudVertex.packed) == json(cloudVertexRet.packed)
#@test json(cloudVertex.bigData) == json(cloudVertexRet.bigData)
@show "Expected = ", json(cloudVertex.properties)
@show "Received = ", json(cloudVertexRet.properties)
@test json(cloudVertex.properties) == json(cloudVertexRet.properties)
@test cloudVertex.neo4jNodeId == cloudVertexRet.neo4jNodeId
@test cloudVertexRet.neo4jNode != Nothing
println("Success!")

print("[TEST] Testing the update method...")
cloudVertex.properties["age"] = 100;
cloudVertex.properties["latestEstimate"] = [5.0, 5.0, 5.0];
CloudGraphs.update_vertex!(cloudGraph, cloudVertex, false);
# Let's retrieve it and see if it is updated.
cloudVertexRet = CloudGraphs.get_vertex(cloudGraph, cloudVertex.neo4jNode.id, false)
# And check that it matches
@show json(cloudVertexRet.properties);
@test json(cloudVertex.properties) == json(cloudVertexRet.properties);
println("Success!")

# Label testing
println("[Test] Creating a vertex with labels...")
cloudVertexWithLabels = deepcopy(cloudVertex);
cloudVertexWithLabels.labels = ["LABEL1", "LABEL2"];
CloudGraphs.add_vertex!(cloudGraph, cloudVertexWithLabels);
println("Success!")
println("[Test] Getting the vertex and checking labels exist...")
cloudVertexWithLabelsRet = CloudGraphs.get_vertex(cloudGraph, cloudVertexWithLabels.neo4jNode.id, false)
@test length(setdiff(cloudVertexWithLabels.labels, cloudVertexWithLabelsRet.labels)) == 0
println("[Test] Adding a label...")
push!(cloudVertexWithLabels.labels, "AnotherLabel")
CloudGraphs.update_vertex!(cloudGraph, cloudVertexWithLabels, false);
cloudVertexWithLabelsRet = CloudGraphs.get_vertex(cloudGraph, cloudVertexWithLabels.neo4jNode.id, false)
@test length(setdiff(cloudVertexWithLabels.labels, cloudVertexWithLabelsRet.labels)) == 0
println("Success!")
# Now clear out all the labels
println("[Test] Clearing all labels...")
cloudVertexWithLabels.labels = Vector{AbstractString}()
CloudGraphs.update_vertex!(cloudGraph, cloudVertexWithLabels, false);
cloudVertexWithLabelsRet = CloudGraphs.get_vertex(cloudGraph, cloudVertexWithLabels.neo4jNode.id, false)
@test length(setdiff(cloudVertexWithLabels.labels, cloudVertexWithLabelsRet.labels)) == 0
println("Success!")

print("[TEST] Deleting a CloudGraph vertex...")
CloudGraphs.delete_vertex!(cloudGraph, cloudVertex);
CloudGraphs.delete_vertex!(cloudGraph, cloudVertexWithLabels);
println("Success!")

print("[TEST] Negative testing for double deletions...")
# Testing a double-delete
try
  CloudGraphs.delete_vertex!(cloudGraph, cloudVertex);
catch
  print("Success!")
end
# Testing the deletion of an apparently existing node
@test_throws ErrorException CloudGraphs.delete_vertex!(cloudGraph, cloudVertexRet);
print("Success!")

print("[TEST] Making an edge...")
# Create two vertices
cloudVert1 = deepcopy(cloudVertex);
cloudVert1.properties["label"] = "Sam's Vertex 1";
cloudVert2 = deepcopy(cloudVertex);
cloudVert2.properties["label"] = "Sam's Vertex 2";
cloudVert3 = deepcopy(cloudVertex);
cloudVert3.properties["label"] = "Sam's Vertex 3";
CloudGraphs.add_vertex!(cloudGraph, cloudVert1);
CloudGraphs.add_vertex!(cloudGraph, cloudVert2);
CloudGraphs.add_vertex!(cloudGraph, cloudVert3);

# Create an edge and add it to the graph.
# Test props
props = Dict{AbstractString, Any}(string("Test") => 8); #UTF8String   utf8(..)
edge12 = CloudGraphs.CloudEdge(cloudVert1, cloudVert2, "DEPENDENCE");
CloudGraphs.add_edge!(cloudGraph, edge12);
edge23 = CloudGraphs.CloudEdge(cloudVert2, cloudVert3, "DEPENDENCE");
CloudGraphs.add_edge!(cloudGraph, edge23);
edge31 = CloudGraphs.CloudEdge(cloudVert3, cloudVert1, "DEPENDENCE");
CloudGraphs.add_edge!(cloudGraph, edge31);
@test edge12.neo4jEdge != nothing
@test edge12.neo4jEdgeId != -1
@test edge23.neo4jEdge != nothing
@test edge23.neo4jEdgeId != -1
@test edge31.neo4jEdge != nothing
@test edge31.neo4jEdgeId != -1
println("Success!")

print("[TEST] Get edge from graph...")
gotedge = CloudGraphs.get_edge(cloudGraph, edge12.neo4jEdgeId)
@test typeof(gotedge) == CloudGraphs.CloudEdge
@test edge12.neo4jEdgeId == gotedge.neo4jEdgeId
@test gotedge.neo4jEdge != edge12.neo4jEdge
@test edge12.edgeType == gotedge.edgeType
@test edge12.neo4jSourceVertexId == gotedge.neo4jSourceVertexId
@test edge12.neo4jDestVertexId == gotedge.neo4jDestVertexId
@test edge12.properties == gotedge.properties

function testCloudGraphsNodeCompares(a::Neo4j.Node, b::Neo4j.Node)
  @test a.paged_traverse == b.paged_traverse
  @test a.labels == b.labels
  @test a.outgoing_relationships == b.outgoing_relationships
  @test a.traverse == b.traverse
  @test a.all_typed_relationships == b.all_typed_relationships
  @test a.all_relationships == b.all_relationships
  @test a.property == b.property
  @test a.self == b.self
  @test a.outgoing_typed_relationships == b.outgoing_typed_relationships
  @test a.properties == b.properties
  @test a.incoming_relationships == b.incoming_relationships
  @test a.incoming_typed_relationships == b.incoming_typed_relationships
  @test a.id == b.id
  # ignore packed data
  # @test a.data == b.data
  nothing
end

testCloudGraphsNodeCompares(edge12.DestVertex.neo4jNode, gotedge.DestVertex.neo4jNode)
testCloudGraphsNodeCompares(edge12.SourceVertex.neo4jNode, gotedge.SourceVertex.neo4jNode)

@test json(edge12.SourceVertex.packed) == json(gotedge.SourceVertex.packed)
@test edge12.SourceVertex.properties == gotedge.SourceVertex.properties
  #@test  edge.SourceVertex.bigData == gotedge.SourceVertex.bigData
@test   edge12.SourceVertex.neo4jNodeId == gotedge.SourceVertex.neo4jNodeId
# @test   edge12.SourceVertex.neo4jNode == gotedge.SourceVertex.neo4jNode
@test   edge12.SourceVertex.isValidNeoNodeId == gotedge.SourceVertex.isValidNeoNodeId
# @test   edge12.SourceVertex.exVertexId == gotedge.SourceVertex.exVertexId
@test   edge12.SourceVertex.isValidExVertex == gotedge.SourceVertex.isValidExVertex
println("Success!")

print("[TEST] Finding all neighbors of a vertex...")
neighs1 = CloudGraphs.get_neighbors(cloudGraph, cloudVert1)
neighs1in = CloudGraphs.get_neighbors(cloudGraph, cloudVert1, incoming=true, outgoing=false)
neighs1out = CloudGraphs.get_neighbors(cloudGraph, cloudVert1, incoming=false, outgoing=true)

@show neighs1
@test length(neighs1) == 2
@test length(neighs1in) == 1
@test length(neighs1out) == 1
@test neighs1[1].neo4jNodeId == cloudVert3.neo4jNodeId || neighs1[2].neo4jNodeId == cloudVert3.neo4jNodeId
@test neighs1[1].neo4jNodeId == cloudVert2.neo4jNodeId || neighs1[2].neo4jNodeId == cloudVert2.neo4jNodeId
@test neighs1in[1].neo4jNodeId == cloudVert3.neo4jNodeId
@test neighs1out[1].neo4jNodeId == cloudVert2.neo4jNodeId
println("Success!")

print("[TEST] Deleting an edge...")
CloudGraphs.delete_edge!(cloudGraph, edge12)
CloudGraphs.delete_edge!(cloudGraph, edge23)
CloudGraphs.delete_edge!(cloudGraph, edge31)
neighs = CloudGraphs.get_neighbors(cloudGraph, cloudVert1)
@test length(neighs) == 0
@test edge12.neo4jEdgeId == -1
@test edge12.neo4jEdge == nothing
println("Success!")

print("[TEST] Deleting nodes...")
CloudGraphs.delete_vertex!(cloudGraph, cloudVert1)
@test cloudVert1.neo4jNode == nothing
@test cloudVert1.neo4jNodeId == -1
CloudGraphs.delete_vertex!(cloudGraph, cloudVert2)
@test cloudVert2.neo4jNode == nothing
@test cloudVert2.neo4jNodeId == -1
CloudGraphs.delete_vertex!(cloudGraph, cloudVert3)
@test cloudVert3.neo4jNode == nothing
@test cloudVert3.neo4jNodeId == -1
println("Success!")
