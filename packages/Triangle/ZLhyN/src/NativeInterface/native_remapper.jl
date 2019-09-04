mutable struct TriangulateInputMapper
  originalVerticesMarkers::Vector{Cint}
  remappedVerticesMarkers::Vector{Cint}
  originalEdgesList::Vector{Cint}
  remappedEdgesList::Vector{Cint}
  TriangulateInputMapper() = new(Vector{Cint}(), Vector{Cint}(), Vector{Cint}(), Vector{Cint}())
end

function trimap_to_native(verticesMap::Vector{Cint}, edges::Vector{Cint} = Vector{Cint}())
    nativeMap = TriangulateInputMapper()

    nativeMap.originalVerticesMarkers = verticesMap
    nativeMap.remappedVerticesMarkers = collect(1:length(verticesMap))
    dictVertices = Dict{Int64,Int64}()
    for (idx,el) in enumerate(verticesMap)
        dictVertices[el] = idx
    end

    if length(edges) > 0
        nativeMap.originalEdgesList = edges
        nativeMap.remappedEdgesList = Vector{Cint}()
        for el in edges
            push!(nativeMap.remappedEdgesList, dictVertices[el])
        end
    end

    return nativeMap
end

function trimap_from_native(nativeMap::TriangulateInputMapper, trianglelist::Vector{Cint})
    newtrianglelist = Vector{Cint}(undef, length(trianglelist))

    for (idx,el) in enumerate(trianglelist)
        newtrianglelist[idx] = nativeMap.originalVerticesMarkers[el]
    end

    return newtrianglelist
end