# REAL = double = Cdouble

mutable struct TriangulateIO
  pointlist::Ptr{Cdouble}
  pointattributelist::Ptr{Cdouble}
  pointmarkerlist::Ptr{Cint}
  numberofpoints::Cint
  numberofpointattributes::Cint
  trianglelist::Ptr{Cint}
  triangleattributelist::Ptr{Cdouble}
  trianglearealist::Ptr{Cdouble}
  neighborlist::Ptr{Cint}
  numberoftriangles::Cint
  numberofcorners::Cint
  numberoftriangleattributes::Cint
  segmentlist::Ptr{Cint}
  segmentmarkerlist::Ptr{Cint}
  numberofsegments::Cint
  holelist::Ptr{Cdouble}
  numberofholes::Cint
  regionlist::Ptr{Cdouble}
  numberofregions::Cint
  edgelist::Ptr{Cint}
  edgemarkerlist::Ptr{Cint}
  normlist::Ptr{Cdouble}
  numberofedges::Cint
  TriangulateIO() = new(C_NULL, C_NULL, C_NULL, 0, 0, C_NULL, C_NULL, C_NULL, C_NULL, 0, 0, 0, C_NULL, C_NULL, 0, C_NULL, 0, C_NULL, 0, C_NULL, C_NULL, C_NULL, 0)
end