

function out_neighbors(cg::CloudGraphs, nodeid::Int64)
  q = "match (n)-[:RELATION]-(neig) where id(n) = $(nodeid) return neig"

end

function out_neighbors(cg::CloudGraphs, nodesymb::ASCIIString)
  q = "match (n)-[:RELATION]-(neig) where n.symbol = $(nodesymb) return neig"

end
