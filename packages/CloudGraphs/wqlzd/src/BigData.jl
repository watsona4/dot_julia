#Functions
export save_BigData!, read_BigData!, update_NeoBigDataEntries!, read_MongoData, delete_MongoData

# --- Internal utility methods ---

"""
    _saveBigDataElement!(cg, vertex, bDE)

Insert or update the actual data payload into Mongo as required. Does not update Neo4j.
"""
function _saveBigDataElement!(cg::CloudGraph, bDE::BigDataElement)::Nothing
  saveTime = string(Dates.now(Dates.UTC));

  # 1. Get the collection name, if set...
  collection = cg.mongo.cgBindataCollection
  # DB customization for multitenancy
  if(haskey(bDE.sourceParams, "database") && haskey(bDE.sourceParams, "collection"))
      collection = cg.mongo.client[bDE.sourceParams["database"]][bDE.sourceParams["collection"]]
  elseif(haskey(bDE.sourceParams, "collection"))
      collection = cg.mongo.client[_mongoDefaultDb][bDE.sourceParams["collection"]]
  end

  # 2. Check if the key exists...
  isNew = true;
  if(bDE.sourceId != "")
    numNodes = length(collection, Mongoc.BSON("""{ "cgId": "$(bDE.sourceId)" }""") )
    isNew = numNodes == 0;
  end
  if(isNew)
    # Insert the node (additional parameters for user readability, data is all that matters)
    bsonDoc = Mongoc.BSON()
    bsonDoc["cgId"] = bDE.sourceId
    bsonDoc["elementId"] = bDE.id
    bsonDoc["description"] = bDE.description
    bsonDoc["data"] = bDE.data
    bsonDoc["mimeType"] = bDE.mimeType
    bsonDoc["neoNodeId"] = bDE.neoNodeId
    bsonDoc["lastSavedTimestamp"] = saveTime
    m_oid = push!(collection, bsonDoc)
    # m_oid = insert(collection, ("cgId" =>  bDE.sourceId, "elementId" => bDE.id, "description" => bDE.description, "data" => bDE.data, "mimeType" => bDE.mimeType, "neoNodeId" => bDE.neoNodeId, "lastSavedTimestamp" => saveTime))
    @info "Inserted big data to mongo id = $(m_oid) for cgId = $(bDE.id)"
  else
    # Update the node
    selector = Mongoc.BSON("""{ "cgId": "$(bDE.sourceId)" }""")
    bsonDoc = Mongoc.BSON()
    # bsonDoc["cgId"] = bDE.sourceId # this is the selector we are using, so don't update
    bsonDoc["elementId"] = bDE.id
    bsonDoc["description"] = bDE.description
    bsonDoc["data"] = bDE.data
    bsonDoc["mimeType"] = bDE.mimeType
    bsonDoc["neoNodeId"] = bDE.neoNodeId
    bsonDoc["lastSavedTimestamp"] = saveTime
    setDoc = Mongoc.BSON()
    setDoc["\$set"] = bsonDoc
    m_oid = Mongoc.update_one(collection, selector, setDoc)
    # m_oid = update(collection, ("cgId" => bDE.sourceId), set("elementId" => bDE.id, "description" => bDE.description, "data" => bDE.data, "mimeType" => bDE.mimeType, "neoNodeId" => bDE.neoNodeId, "lastSavedTimestamp" => saveTime))
    @info "Updated big data to mongo id (result=$(m_oid)) for cgId $(bDE.id)"
  end
  return nothing
end

# ------

"""
    update_NeoBigDataEntries!(cg, vertex)

Update the bigData dictionary elements in Neo4j. Does not insert or read from Mongo.
"""
function update_NeoBigDataEntries!(cg::CloudGraph, vertex::CloudVertex)::Nothing
  savedSets = Vector{BigDataRawType}(); #Vector{savedSets = BigDataRawType}();
  for elem in vertex.bigData.dataElements
    # keep big data separate during Neo4j updates and remerge at end
    push!(savedSets, elem.data);
    elem.data = Dict{String, Any}();
  end
  vertex.bigData.isExistingOnServer = true;
  vertex.bigData.lastSavedTimestamp = string(Dates.now(Dates.UTC));

  # Get the json bigData prop.
  bdProp = json(vertex.bigData);
  # Now put the data back
  i = 0;
  for elem in vertex.bigData.dataElements
    i += 1;
    elem.data = savedSets[i];
  end

  #Update the bigdata property
  setnodeproperty(vertex.neo4jNode, "bigData", bdProp);
  return(nothing)
end

function save_BigData!(cg::CloudGraph, vertex::CloudVertex)::Nothing
  #Write to Mongo
  for bDE in vertex.bigData.dataElements
    _saveBigDataElement!(cg, bDE);
  end

  #Now update the Neo4j node.
  update_NeoBigDataEntries!(cg, vertex)
  return(nothing)
end

function read_MongoData(cg::CloudGraph, bDE::BigDataElement)::BigDataRawType
    # 1. Get the collection name, if set...
    collection = cg.mongo.cgBindataCollection
    # DB customization for multitenancy
    if(haskey(bDE.sourceParams, "database") && haskey(bDE.sourceParams, "collection"))
        # collection = Mongo.MongoCollection(cg.mongo.client, bDE.sourceParams["database"], bDE.sourceParams["collection"]);
        collection = cg.mongo.client[bDE.sourceParams["database"]][bDE.sourceParams["collection"]]
    elseif(haskey(bDE.sourceParams, "collection"))
        # collection = Mongo.MongoCollection(cg.mongo.client, _mongoDefaultDb, bDE.sourceParams["collection"]);
        collection = cg.mongo.client[_mongoDefaultDb][bDE.sourceParams["collection"]]
    end

    # 2. See if the element exists
    numNodes = length(collection, Mongoc.BSON("""{ "cgId": "$(bDE.sourceId)" }""") )
    # numNodes = count(collection, ("cgId" => bDE.sourceId));
    if(numNodes != 1)
      error("The query for data elements named $(bDE.id) with Mongo CGID $(bDE.sourceId) returned $(numNodes) values, expected 1 result for this element!");
    end
    results = Mongoc.find_one(collection, Mongoc.BSON("""{ "cgId": "$(bDE.sourceId)" }""") )
    # results = first(find(collection, ("cgId" => bDE.sourceId)))

    #Have it, now parse it until we have a native binary or dictionary datatype.
    # If new type, convert back to dictionary

    if(typeof(results) == Mongoc.BSON)
        dict = Mongoc.as_dict(results)
        return dict["data"]      # testOutput = dict(results["data"]);
        # return convert(Dict{String, Any}, testOutput) #From {Any, Any} to a more comfortable stronger type
    else
        return results["data"];
    end
end

function delete_MongoData(cg::CloudGraph, bDE::BigDataElement)::Nothing
    # 1. Get the collection name, if set...
    collection = cg.mongo.cgBindataCollection
    # DB customization for multitenancy
    if(haskey(bDE.sourceParams, "database") && haskey(bDE.sourceParams, "collection"))
        collection = cg.mongo.client[bDE.sourceParams["database"]][bDE.sourceParams["collection"]]
        # collection = Mongo.MongoCollection(cg.mongo.client, bDE.sourceParams["database"], bDE.sourceParams["collection"]);
    elseif(haskey(bDE.sourceParams, "collection"))
        collection = cg.mongo.client[_mongoDefaultDb][bDE.sourceParams["collection"]]
        # collection = Mongo.MongoCollection(cg.mongo.client, _mongoDefaultDb, bDE.sourceParams["collection"]);
    end

    # 2. See if the element exists
    selector = Mongoc.BSON("""{ "cgId": "$(bDE.sourceId)" }""")
    numNodes = length(collection, selector);

    if(numNodes != 1)
      error("The query for data elements named $(bDE.id) with Mongo CGID $(bDE.sourceId) returned $(numNodes) values, expected 1 result for this element!");
    end
    Mongoc.delete_one(collection, selector)
    @info "Deleted big data mongo id = $(bDE.sourceId) for cgId = $(bDE.id)"

    return(nothing)
end

function read_BigData!(cg::CloudGraph, vertex::CloudVertex)::BigData
  if(vertex.bigData.isExistingOnServer == false)
    error("The data does not exist on the server. 'isExistingOnServer' is false. Have you saved with set_BigData!()");
  end
  for bDE in vertex.bigData.dataElements
      #TODO: Handle the different source types.
      bDE.data = read_MongoData(cg, bDE)
  end
  vertex.bigData.isRetrieved = true
  return(vertex.bigData)
end

function delete_BigData!(cg::CloudGraph, vertex::CloudVertex)::Nothing
  if(vertex.bigData.isExistingOnServer == false)
    error("The data does not exist on the server. 'isExistingOnServer' is false. Have you saved with set_BigData!()");
  end
  # Update structure now so if it fails midway and we save again it still writes a new set of keys.
  vertex.bigData.isExistingOnServer = false
  # Delete the data.
  for bDE in vertex.bigData.dataElements
      delete_MongoData(cg, bDE)
  end
  # Delete the entries and update the indices
  empty!(vertex.bigData.dataElements)
  update_NeoBigDataEntries!(cg, vertex)
  return(nothing)
end
