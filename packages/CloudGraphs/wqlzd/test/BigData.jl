# Setup everything using the common setup.
include("CloudGraphSetup.jl")

@testset "Encoding and decoding of packed data types" begin
    # And check that if we encode and decode this type, it's exactly the same.
    # Make a packed data test structure.
    global fullType = DataTest(rand(10,10), "This is a test string", rand(Int32,10,10));
    typePackedRegName = string(PackedDataTest);
    typeOriginalRegName = string(DataTest);
    # Now lets encode and decode to see.
    testPackedType = convert(PackedDataTest, fullType);
    # testPackedType = cloudGraph.packedOriginalDataTypes[typeOriginalRegName].encodingFunction(PackedDataTest, fullType);

    testFullType = convert(DataTest, testPackedType)
    # testFullType = cloudGraph.packedPackedDataTypes[typePackedRegName].decodingFunction(DataTest, testPackedType);

    @test json(testFullType) == json(fullType)
end

# bsonDoc = Mongoc.BSON()
# bsonDoc["test"] = 1

@testset "BigData testing" begin

cloudVertex = CloudGraphs.CloudVertex()

@testset "Creating a CloudVertex from an ExVertex with bigdata elements..." begin

localGraph = graph(ExVertex[], ExEdge{ExVertex}[]);
#Make an ExVertex that may be encoded
v = make_vertex(localGraph, "TestVertex");
vertex = Graphs.add_vertex!(localGraph, v);
vertex.attributes["data"] = fullType;
vertex.attributes["age"] = 64;
vertex.attributes["latestEstimate"] = [0.0,0.0,0.0];
bigData = CloudGraphs.BigData();
testElementLegacy = CloudGraphs.BigDataElement("TestElement1", "Performance test dataset legacy.", rand(UInt8,100), -1); #Data element
testElementDict = CloudGraphs.BigDataElement("TestElement2", "Performance test dataset new dict type.", Dict{String, Any}("testString"=>"Test String", "randUint8"=>rand(UInt8,100)), -1); #Data element
append!(bigData.dataElements, [testElementLegacy, testElementDict]);
vertex.attributes["bigData"] = bigData;
# Now encoding the structure to CloudGraphs vertex
cloudVertex = CloudGraphs.exVertex2CloudVertex(vertex);

end

cloudNodeId = -1

@testset "Adding a vertex with bigdata elements..." begin

CloudGraphs.add_vertex!(cloudGraph, cloudVertex);
cloudNodeId = cloudVertex.neo4jNode.id
@test cloudVertex.neo4jNode.id != -1

end

@testset "Checking the big data is persisted for NeoNode $cloudNodeId..." begin

cloudVertexRet = CloudGraphs.get_vertex(cloudGraph, cloudNodeId, true) # fullType not required
@test length(cloudVertexRet.bigData.dataElements) == 2
@test cloudVertexRet.bigData.dataElements[1].data == cloudVertex.bigData.dataElements[1].data
@test json(cloudVertexRet.bigData.dataElements[2].data) == json(cloudVertex.bigData.dataElements[2].data)
@test cloudVertexRet.bigData.isRetrieved

end

@testset "Testing bigdata update method..." begin

cloudVertexOrig = CloudGraphs.get_vertex(cloudGraph, cloudNodeId, true) # fullType not required
cloudVertexUpdate = CloudGraphs.get_vertex(cloudGraph, cloudNodeId, true) # fullType not required
cloudVertexUpdate.bigData.dataElements[1].description = "Updated!"
cloudVertexUpdate.bigData.dataElements[1].data = zeros(UInt8,100)
update_vertex!(cloudGraph, cloudVertexUpdate, true)
cloudVertexRet = CloudGraphs.get_vertex(cloudGraph, cloudNodeId, true) # fullType not required
@test cloudVertexRet.bigData.dataElements[1].data != cloudVertexOrig.bigData.dataElements[1].data

end

# Saving an image as binary in a separate collection
@testset "Saving a raw string..." begin

cloudVertex = CloudGraphs.get_vertex(cloudGraph, cloudNodeId, true) # fullType not required

sourceParams = Dict{String, Any}("database" => "TestCGRepo", "collection" => "RawImages")
testElementString = CloudGraphs.BigDataElement("TestString", "String test! Lots of lorem ipsums", "String test! Lots of lorem ipsums", -1, mimeType="application/text");
push!(cloudVertex.bigData.dataElements, testElementString);
update_vertex!(cloudGraph, cloudVertex, true)
# Reading it back to see if all is good.
bDEData = read_MongoData(cloudGraph, testElementString)
@test testElementString.data == bDEData

end


# Saving an image as binary in a separate collection
@testset "Saving an image to a custom database/collection..." begin

cloudVertex = CloudGraphs.get_vertex(cloudGraph, cloudNodeId, true) # fullType not required
fid = open(dirname(Base.source_path()) * "/IMG_1407.JPG","r")
imgBytes = read(fid)
close(fid)

sourceParams = Dict{String, Any}("database" => "TestCGRepo", "collection" => "RawImages")
testElementImg = CloudGraphs.BigDataElement("TestImage", "Image Test", imgBytes, -1, sourceParams=sourceParams); #Data element
push!(cloudVertex.bigData.dataElements, testElementImg);
update_vertex!(cloudGraph, cloudVertex, true)
# Reading it back to see if all is good
bDEData = read_MongoData(cloudGraph, testElementImg)
@test testElementImg.data == bDEData

end

@testset "Deleting nodes and all bigdata..." begin

cloudVertexGet = CloudGraphs.get_vertex(cloudGraph, cloudNodeId, true) # fullType not required
delete_vertex!(cloudGraph, cloudVertexGet)
@test cloudVertexGet.neo4jNode == nothing
@test cloudVertexGet.neo4jNodeId == -1

# TODO restore
# @fact_throws ErrorException CloudGraphs.get_vertex(cloudGraph, cloudNodeId, true) # fullType not required

# Going deeper for underlying read failure on bigdata
cloudVertex.bigData.dataElements[1].sourceId = "DoesntExist"
# TODO restore
# @fact_throws ErrorException CloudGraphs.read_BigData!(cloudGraph, cloudVertex)
end
end
