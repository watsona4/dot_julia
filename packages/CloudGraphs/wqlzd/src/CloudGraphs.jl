module CloudGraphs

import Graphs: add_edge!, add_vertex!

using Graphs
using Neo4j
# using Mongo
# using LibBSON
using Mongoc
using ProtoBuf
using JSON
using Dates

# extending methods

#Functions
export connect, disconnect, add_vertex!, get_vertex, update_vertex!, delete_vertex!
export add_edge!, delete_edge!, get_edge
export get_neighbors
export cloudVertex2ExVertex, exVertex2CloudVertex
export registerPackedType!, unpackNeoNodeData2UsrType

include("CommonStructs.jl")
include("BigData.jl")

# WHenever bigData is saved, we upgrade it to the latest version.
BIGDATA_CURVERSION = "2"

# --- CloudGraph initialization ---
function connect(configuration::CloudGraphConfiguration, encodefnc::Function, gpt::Function, dpt::Function)
  neoConn = Neo4j.Connection(configuration.neo4jHost, port=configuration.neo4jPort, user=configuration.neo4jUsername, password=configuration.neo4jPassword);
  neo4j = Neo4jInstance(neoConn, Neo4j.getgraph(neoConn));

  mongostr = "mongodb://" * configuration.mongoUsername * ":"* configuration.mongoPassword * "@" * configuration.mongoHost * "/?authSource=admin"
  mongoClient = configuration.mongoIsUsingCredentials ? Mongoc.Client(mongostr) : Mongoc.Client(configuration.mongoHost, configuration.mongoPort)
  cgBindataCollection = mongoClient[_mongoDefaultDb][_mongoDefaultCollection]
  mongoInstance = MongoDbInstance(mongoClient, cgBindataCollection);
  # mongoClient = configuration.mongoIsUsingCredentials ? Mongo.MongoClient(configuration.mongoHost, configuration.mongoPort, configuration.mongoUsername, configuration.mongoPassword) : Mongo.MongoClient(configuration.mongoHost, configuration.mongoPort)
  # cgBindataCollection = Mongo.MongoCollection(mongoClient, _mongoDefaultDb, _mongoDefaultCollection);
  # mongoInstance = MongoDbInstance(mongoClient, cgBindataCollection);

  return CloudGraph(configuration, neo4j, mongoInstance, encodefnc, gpt, dpt);
end

# --- CloudGraph shutdown ---
function disconnect(cloudGraph::CloudGraph)

end

# --- Common conversion functions ---
function exVertex2CloudVertex(vertex::ExVertex)::CloudVertex
  cgvProperties = Dict{String, Any}();

  #1. Get the special attributes - payload, etc.
  propNames = keys(vertex.attributes);
  if("bigData" in propNames) #We have big data to save.
    bigData = vertex.attributes["bigData"];
  else
    bigData = BigData();
  end
  if haskey(vertex.attributes, "data") #("data" in propNames) #We have protobuf stuff to save in the node.
    packed = vertex.attributes["data"];
  else
    packed = "";
  end
  #2. Transfer everything else to properties
  for (k,v) in vertex.attributes
    if(k != "bigData" && k != "data")
      cgvProperties[k] = v;
    end
  end
  #3. Encode the packed data and big data.
  return CloudVertex(packed, cgvProperties, bigData, -1, nothing, false, vertex.index, false);
end

function cloudVertex2ExVertex(vertex::CloudVertex)::Graphs.ExVertex
  # create an ExVertex
  vert = Graphs.ExVertex(vertex.exVertexId, vertex.properties["label"])
  vert.attributes = Graphs.AttributeDict()
  vert.attributes = vertex.properties

  # populate the data container
  vert.attributes["data"] = vertex.packed
  return vert
end

function cloudVertex2NeoProps(cg::CloudGraph, vertex::CloudVertex)
  props = deepcopy(vertex.properties);

  #If the vertex has packed data.
  if(vertex.packed != "")
      # Packed information
      pB = PipeBuffer();

      ## Dropping the type registration requirement
      packedType = cg.encodePackedType(vertex.packed)
      ProtoBuf.writeproto(pB, packedType); # vertex.packed
      typeKey = string(typeof(packedType));

      props["data"] = pB.data;
      props["packedType"] = typeKey;
  end
  # Big data
  # Write it.
  # Clear the underlying data in the Neo4j dataset and serialize the big data.
  savedSets = Vector{Union{Vector{UInt8}, Dict{String, Any}, Dict{Any, Any}, String}}();  # like so?
  for elem in vertex.bigData.dataElements
    push!(savedSets, elem.data);
    elem.data = Dict{String, Any}();
  end
  props["bigData"] = json(vertex.bigData);
  # Now put it back
  i = 1;
  for elem in vertex.bigData.dataElements
    elem.data = savedSets[i];
    i = i +1;
  end

  props["exVertexId"] = vertex.exVertexId

  return props;
end

function unpackNeoNodeData2UsrType(cg::CloudGraph, neoNode::Neo4j.Node)
  props = neoNode.data;

  # Unpack the packed data using an interim UInt8[].
  if !haskey(props, "data")
    error("dont have data field in neoNode id=$(neoNode.id)")
  end
  pData = convert(Array{UInt8,1}, props["data"]);
  pB = PipeBuffer(pData);

  typePackedRegName = props["packedType"];
  packedtype = cg.getpackedtype(typePackedRegName) # combine in DFG, ProtoBuf
  packed = readproto(pB, packedtype); # TODO should be moved to common DIstributedFactorGraphs.jl
  fulltype = cg.decodePackedType(packed,typePackedRegName) # combine in DFG, ProtoBuf
  return fulltype
end


function neoNode2CloudVertex(cg::CloudGraph, neoNode::Neo4j.Node)
  # Get the node properties.
  recvOrigType = nothing
  # try
      recvOrigType = unpackNeoNodeData2UsrType(cg, neoNode)
  # catch err
  #     println("Could not convert packed type, please check your conversion function.")
  #     error(err)
  # end
  props = neoNode.data;

  # Big data
  jsonBD = props["bigData"];
  bDS = JSON.parse(jsonBD);
  # new addition of the timestamp.
  ts = bDS["lastSavedTimestamp"];
  version = haskey(bDS, "version") ? bDS["version"] : "1"
  bigData = BigData(bDS["isRetrieved"], bDS["isAvailable"], bDS["isExistingOnServer"], ts, version, Vector{BigDataElement}());
  # TODO [GearsAD]: Remove the haskey again in the future once all nodes are up to date.
  if(haskey(bDS, "dataElements"))
    for bDE in bDS["dataElements"]
        elem = BigDataElement(bDE, version)
        push!(bigData.dataElements, elem)
    end
  end

  #In-situ version update in case it's saved back
  bigData.version = BIGDATA_CURVERSION;

  labels = convert(Vector{String}, Neo4j.getnodelabels(neoNode));
  if(length(labels) == 0)
    labels = Vector{String}();
  end

  # Now delete these out the props leaving the rest as general properties
  delete!(props, "data");
  delete!(props, "packedType");
  delete!(props, "bigData");
  exvid = props["exVertexId"]
  delete!(props, "exVertexId")

  # Build a CloudGraph nrecvOrigTypeode.
  return CloudVertex(recvOrigType, props, bigData, neoNode.metadata["id"], neoNode, true, exvid, false; labels=labels);
end

# --- Graphs.jl overloads ---

function add_vertex!(cg::CloudGraph, vertex::ExVertex)
  add_vertex!(cg, exVertex2CloudVertex(vertex));
end

function add_vertex!(cg::CloudGraph, vertex::CloudVertex)::Int
  try
    props = cloudVertex2NeoProps(cg, vertex)
    vertex.neo4jNode = Neo4j.createnode(cg.neo4j.graph, props);
    # Set the labels
    if(length(vertex.labels) > 0)
      Neo4j.addnodelabels(vertex.neo4jNode, vertex.labels);
    end
    # Update the Neo4j info.
    vertex.neo4jNodeId = vertex.neo4jNode.id;
    vertex.isValidNeoNodeId = true;
    # Save this bigData
    save_BigData!(cg, vertex);
    # make sure original struct gets the new bits of data it should have -- rather show than hide?
    # for ky in ["data"; "packedType"]  vertex.properties[ky] = props[ky] end
    return vertex.neo4jNodeId;
  catch e
    rethrow(e)
  end
end

# Get a CloudGraphs vertex.
function get_vertex(cg::CloudGraph, neoNodeId::Int, retrieveBigData::Bool)
    neoNode = Neo4j.getnode(cg.neo4j.graph, neoNodeId);
    cgVertex = neoNode2CloudVertex(cg, neoNode);
    if(retrieveBigData && cgVertex.bigData.isExistingOnServer)
        read_BigData!(cg, cgVertex);
    # try
    # catch ex
    #     println(catch_stacktrace())
    #     @warn "Unable to retrieve bigData for node ID '$(neoNodeId)' - $(ex)"
    # end
    end
    return(cgVertex)
end

function update_vertex!(cg::CloudGraph, vertex::CloudVertex, updateBigData::Bool)::Nothing
  try
    if(vertex.neo4jNode == nothing)
      error("There isn't a Neo4j Node associated with this CloudVertex. You might want to call add_vertex instead of update_vertex.");
    end

    props = cloudVertex2NeoProps(cg, vertex);
    Neo4j.updatenodeproperties(vertex.neo4jNode, props);

    # Update the labels
    Neo4j.updatenodelabels(vertex.neo4jNode, vertex.labels);

    # Update the BigData
    if(updateBigData)
        @info "Updating bigData for node $(vertex.neo4jNodeId)..."
        save_BigData!(cg, vertex)
    end

    return nothing
  catch e
    rethrow(e);
  end
end

function delete_vertex!(cg::CloudGraph, vertex::CloudVertex)::Nothing
  if(vertex.neo4jNode == nothing)
    error("There isn't a Neo4j Node associated with this CloudVertex.");
  end

  try
    delete_BigData!(cg, vertex)
  catch ex
    if(isa(ex, ErrorException))
        @warn "Unable to completely delete bigData for node $(vertex.neo4jNodeId) - $(ex)"
    else
        error(ex)
    end
  end

  Neo4j.deletenode(vertex.neo4jNode);

  vertex.neo4jNode = nothing
  vertex.neo4jNodeId = -1
  vertex.isValidNeoNodeId = false
  return(nothing)
end


function add_edge!(cg::CloudGraph, edge::CloudEdge)
  if(edge.SourceVertex.neo4jNode == nothing)
    error("There isn't a valid source Neo4j in this CloudEdge.");
  end
  if(edge.DestVertex.neo4jNode == nothing)
    error("There isn't a valid destination Neo4j in this CloudEdge.");
  end

  retrel = Neo4j.createrel(edge.SourceVertex.neo4jNode, edge.DestVertex.neo4jNode, edge.edgeType; props=edge.properties );
  edge.neo4jEdge = retrel;
  edge.neo4jEdgeId = retrel.id

  # add destid to sourcevert and visa versa
  if haskey(edge.SourceVertex.properties, "neighborVertexIDs")
    # push!(edge.SourceVertex.properties["neighborVertexIDs"], edge.DestVertex.neo4jNodeId)
    edge.SourceVertex.properties["neighborVertexIDs"] = union(edge.SourceVertex.properties["neighborVertexIDs"], [edge.DestVertex.neo4jNodeId])
  else
    edge.SourceVertex.properties["neighborVertexIDs"] = Array{Int64,1}([edge.DestVertex.neo4jNodeId])
  end
  if haskey(edge.DestVertex.properties, "neighborVertexIDs")
    # push!(edge.DestVertex.properties["neighborVertexIDs"], edge.SourceVertex.neo4jNodeId)
    edge.DestVertex.properties["neighborVertexIDs"] = union(edge.DestVertex.properties["neighborVertexIDs"], [edge.SourceVertex.neo4jNodeId])
  else
    edge.DestVertex.properties["neighborVertexIDs"] = Array{Int64,1}([edge.SourceVertex.neo4jNodeId])
  end

  update_vertex!(cg, edge.SourceVertex, false)
  update_vertex!(cg, edge.DestVertex, false)

  retrel
end

function get_edge(cg::CloudGraph, neoEdgeId::Int)
  try
    neoEdge = Neo4j.getrel(cg.neo4j.graph, neoEdgeId);
    startid = parse(Int,split(neoEdge.relstart,'/')[end])
    endid = parse(Int,split(neoEdge.relend,'/')[end])
    cloudVert1 = CloudGraphs.get_vertex(cg, startid, false)
    cloudVert2 = CloudGraphs.get_vertex(cg, endid, false)
    # Get the node properties.
    # props = neoEdge.data; # TODO
    edge = CloudGraphs.CloudEdge(cloudVert1, cloudVert2, neoEdge.reltype);
    edge.neo4jEdgeId = neoEdge.id
    edge.neo4jEdge = neoEdge

    return edge
  catch e
    rethrow(e);
  end
end

#function update_edge!()
#end

function delete_edge!(cg::CloudGraph, edge::CloudEdge)
  if(edge.SourceVertex == nothing)
    error("There isn't a valid source Neo4j in this CloudEdge.");
  end
  if(edge.DestVertex == nothing)
    error("There isn't a valid destination Neo4j in this CloudEdge.");
  end

  Neo4j.deleterel(edge.neo4jEdge)
  edge.neo4jEdge = nothing;
  edge.neo4jEdgeId = -1;
  # Remove from either nodes.
  edge.SourceVertex.properties["neighborVertexIDs"] = edge.SourceVertex.properties["neighborVertexIDs"][edge.SourceVertex.properties["neighborVertexIDs"] .!= edge.DestVertex.neo4jNodeId];
  edge.DestVertex.properties["neighborVertexIDs"] = edge.DestVertex.properties["neighborVertexIDs"][edge.DestVertex.properties["neighborVertexIDs"] .!= edge.SourceVertex.neo4jNodeId];
  # Update the vertices
  update_vertex!(cg, edge.SourceVertex, false);
  update_vertex!(cg, edge.DestVertex, false);

  nothing;
end

function get_neighbors(cg::CloudGraph, vert::CloudVertex; incoming::Bool=true, outgoing::Bool=true, needdata::Bool=false)
  if(vert.neo4jNode == nothing)
    error("The provided vertex does not have its associated Neo4j Node (vertex.neo4jNode) - please perform a get_vertex to get the complete structure first.")
  end

  loadtx = transaction(cg.neo4j.connection)
  query = "match (node)$(incoming ? "<" : "")-[:DEPENDENCE]-$(outgoing ? ">" : "")(another) where id(node) = $(vert.neo4jNodeId) return id(another)";
  nodes = loadtx(query; submit=true)
  nodes = map(node -> getnode(cg.neo4j.graph, node["row"][1]), nodes.results[1]["data"])
  commit(loadtx)

  neighbors = CloudVertex[]
  for neoNeighbor in nodes
    if !haskey(neoNeighbor.data, "data") && needdata
      @warn "skip neighbor if not in the subgraph segment of interest, neonodeid=$(neoNeighbor.id)"
      continue;
    end
    push!(neighbors, neoNode2CloudVertex(cg, neoNeighbor))
  end
  return(neighbors)
end

end #module
