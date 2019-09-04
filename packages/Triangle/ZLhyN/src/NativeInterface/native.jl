module NativeInterface

include("triangle_structure.jl")
include("options_structure.jl")
include("native_remapper.jl")
include("native_calls.jl")

export TriangulateOptions
export basic_triangulation
export constrained_triangulation
export constrained_triangulation_bounded

function basic_triangulation(vertices::Vector{Cdouble}, verticesMap::Vector{Cint}, options::TriangulateOptions = TriangulateOptions())
  # Call C
  return calculate_output(generate_basic_input(vertices, verticesMap), options)
end

function constrained_triangulation(vertices::Vector{Cdouble}, verticesMap::Vector{Cint}, edges::Vector{Cint}, options::TriangulateOptions = TriangulateOptions())

  # Call C
  return calculate_output(generate_basic_input(vertices, verticesMap, edges), options)
end

function constrained_triangulation_bounded(vertices::Vector{Cdouble}, verticesMap::Vector{Cint}, edges::Vector{Cint}, boundary_edges::Vector{Cint}, options::TriangulateOptions = TriangulateOptions())
  # Call C
  return calculate_output(generate_basic_input(vertices, verticesMap, edges, boundary_edges), options)
end

function constrained_triangulation_bounded(vertices::Vector{Cdouble}, verticesMap::Vector{Cint}, edges::Vector{Cint}, boundary_edges::Vector{Cint}, holes::Vector{Cdouble}, options::TriangulateOptions = TriangulateOptions())
  # Call C
  return calculate_output(generate_basic_input(vertices, verticesMap, edges, boundary_edges, holes), options)
end

function generate_basic_input(vertices::Vector{Cdouble}, verticesMap::Vector{Cint}, edges::Vector{Cint} = Vector{Cint}(), boundary_edges::Vector{Cint} = Vector{Cint}(), holes::Vector{Cdouble} = Vector{Cdouble}())
  # Basic Tri
  # println(vertices)
  # println(verticesMap)

  mapTri = trimap_to_native(verticesMap, edges)

  inTri = TriangulateIO()  
  inTri.pointlist = pointer(vertices)
  inTri.numberofpoints = length(mapTri.remappedVerticesMarkers)
  inTri.pointmarkerlist = pointer(mapTri.remappedVerticesMarkers)
  if length(edges) > 0
    inTri.segmentlist = pointer(mapTri.remappedEdgesList)
    inTri.numberofsegments = Int(length(mapTri.remappedEdgesList)/2)
  end
  if length(edges) > 0 && length(boundary_edges) > 0
    inTri.segmentmarkerlist = pointer(boundary_edges)  
  end
  if length(holes) > 0
    inTri.holelist = pointer(holes)
    inTri.numberofholes = Int(length(holes)/2)
  end

  return (inTri, mapTri)
end

function calculate_output(inputTriData::Tuple{TriangulateIO,TriangulateInputMapper}, options::TriangulateOptions)
  inTri = inputTriData[1]
  mapTri = inputTriData[2]
  
  # Call C
  tupleRes = ctriangulate(inTri, getTriangulateStringOptions(options))
  
  # println( unsafe_wrap(Array, tupleRes[1].pointlist, tupleRes[1].numberofpoints * 2, false) )
  # println( unsafe_wrap(Array, tupleRes[1].pointmarkerlist, tupleRes[1].numberofpoints, false) )  
  # println(tupleRes[1])

  triangleList = unsafe_wrap(Array, tupleRes[1].trianglelist, 
  tupleRes[1].numberoftriangles * tupleRes[1].numberofcorners, own=true)
  
  # Clean C
  inTri.pointlist = C_NULL
  inTri.pointmarkerlist = C_NULL

  tupleRes[1].trianglelist = C_NULL

  # println(triangleList)

  return trimap_from_native(mapTri, triangleList)
end

end