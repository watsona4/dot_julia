depsjl = joinpath(dirname(@__FILE__), "../..", "deps", "deps.jl")
include(depsjl)

function ctriangulate(inTri::TriangulateIO, options::String)
  outTri = TriangulateIO()
  voronoiTri = TriangulateIO()
  
  ccall(
    (:call_triangulate, libtriangle), 
    Nothing, 
    (Ptr{UInt8}, Ref{TriangulateIO}, Ref{TriangulateIO}, Ref{TriangulateIO}), 
    options, Ref(inTri), Ref(outTri), Ref(voronoiTri)
  )

  (outTri, voronoiTri)
end