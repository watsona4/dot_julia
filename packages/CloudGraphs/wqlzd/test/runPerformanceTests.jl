using Base.Test

# Setup everything.
include("CloudGraphSetup.jl")

# Build a basic type
# And check that if we encode and decode this type, it's exactly the same.
# Make a packed data test structure.
fullType = DataTest(rand(10,10), "This is a test string", rand(Int32,10,10));
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
vertex.attributes["bigData"] = bigData;
testElement = CloudGraphs.BigDataElement("Performance test dataset.", Array(UInt8, 1000000)); #1Mb data element
append!(bigData.dataElements, [testElement]);
# Now encoding the structure to CloudGraphs vertex
cloudVertex = CloudGraphs.exVertex2CloudVertex(vertex);

using Mongoc
# function localscope(N=1000000)
  data = ("testId" => Array(UInt8, 10), "description" => "DESCRIPTION")
  @time m_oid = insert(cloudGraph.mongo.cgBindataCollection, data)
  # nothing
# end
myFavouriteKey = first(find(cloudGraph.mongo.cgBindataCollection, ("_id" => eq(m_oid))));


loopCount = 10;
vertices = [];
times = Float32[];
print("[TEST] Testing with $(loopCount) nodes...")

for i = 1:loopCount
  newNode = deepcopy(cloudVertex);
  append!(vertices, [newNode]);
end
# Add a vertex
for i = 1:loopCount
  tic();
  CloudGraphs.add_vertex!(cloudGraph, vertices[i]);
  append!(times, toc());
end
println("Time to add a single vertex = $(mean(times) * 1000.0)ms +- $(std(times)*1000.0)ms");



# Get a vertex
times = Float32[];
for i = 1:loopCount
  tic();
  CloudGraphs.get_vertex(cloudGraph, vertices[i].neo4jNode.id, false);
  append!(times, toq());
end
println("Time to get a single vertex = $(mean(times) * 1000.0)ms +- $(std(times)*1000.0)ms");

# Time to update a vertex (adding labels).
times = Float32[];
for i = 1:loopCount
  vertices[i].labels = ["PerfTesting"];
  tic();
  CloudGraphs.update_vertex!(cloudGraph, vertices[i]);
  append!(times, toq());
end
println("Time to update a single vertex = $(mean(times) * 1000.0)ms +- $(std(times)*1000.0)ms");

println("Success!")
