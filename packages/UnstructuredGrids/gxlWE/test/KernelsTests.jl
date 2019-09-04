module KernelsTests

using Test
using UnstructuredGrids.Kernels

vv = [[1,2,3],[2,3],[5,8],Int[],[1,2,4]]

_data, _ptrs = generate_data_and_ptrs(vv)

data = [1, 2, 3, 2, 3, 5, 8, 1, 2, 4]
ptrs = [1, 4, 6, 8, 8, 11]

@test data == _data
@test ptrs == _ptrs

a = [9,2,1,2,4,7,4]
b = [1,9,2,1,2,4,7]

rewind_ptrs!(a)
@test a == b

a = [3,2,4,2]
b = [1,3,7,9]

length_to_ptrs!(a)
@test a == b

include("Mock2D.jl")

_vertex_to_cells_data, _vertex_to_cells_ptrs = generate_dual_connections(
  cell_to_vertices_data,cell_to_vertices_ptrs)

@test _vertex_to_cells_data == vertex_to_cells_data
@test _vertex_to_cells_ptrs == vertex_to_cells_ptrs

_cell_to_faces_data, _cell_to_faces_ptrs = generate_cell_to_faces(
  cell_to_vertices_data,
  cell_to_vertices_ptrs,
  ctype_to_lface_to_lvertices,
  cell_to_ctype,
  vertex_to_cells_data,
  vertex_to_cells_ptrs)

@test cell_to_faces_data == _cell_to_faces_data
@test cell_to_faces_ptrs == _cell_to_faces_ptrs

_face_to_ftype = generate_face_to_ftype(
  cell_to_faces_data,
  cell_to_faces_ptrs,
  cell_to_ctype,
  ctype_to_lface_to_ftype)

@test face_to_ftype == _face_to_ftype

_face_to_vertices_data, _face_to_vertices_ptrs = generate_face_to_vertices(
  cell_to_vertices_data,
  cell_to_vertices_ptrs,
  cell_to_faces_data,
  cell_to_faces_ptrs,
  cell_to_ctype,
  ctype_to_lface_to_lvertices)

@test face_to_vertices_data == _face_to_vertices_data
@test face_to_vertices_ptrs == _face_to_vertices_ptrs

pa = [1,3,5,7,9]
pb = [1,3,5,7]

pc = append_ptrs(pa,pb)

@test pc == [1, 3, 5, 7, 9, 11, 13, 15]

vertex_to_faces_data, vertex_to_faces_ptrs = generate_dual_connections(
  face_to_vertices_data,face_to_vertices_ptrs)

_cell_to_faces_data, _cell_to_faces_ptrs = find_cell_to_faces(
  cell_to_vertices_data,
  cell_to_vertices_ptrs,
  ctype_to_lface_to_lvertices,
  cell_to_ctype,
  vertex_to_faces_data,
  vertex_to_faces_ptrs)

@test cell_to_faces_data == _cell_to_faces_data
@test cell_to_faces_ptrs == _cell_to_faces_ptrs

face_to_cells_data, face_to_cells_ptrs = generate_dual_connections(
  cell_to_faces_data, cell_to_faces_ptrs)

_face_to_isboundary = generate_facet_to_isboundary(face_to_cells_ptrs)

@test face_to_isboundary == _face_to_isboundary

_vertex_to_isboundary = generate_face_to_isboundary(
  face_to_isboundary,
  vertex_to_faces_data,
  vertex_to_faces_ptrs)

@test vertex_to_isboundary == _vertex_to_isboundary

gface_to_vertices = [[1,2],[2,5],[4,5]]

gface_to_vertices_data, gface_to_vertices_ptrs =
  generate_data_and_ptrs(gface_to_vertices)

gface_to_face = find_gface_to_face(
  face_to_vertices_data,
  face_to_vertices_ptrs,
  vertex_to_faces_data,
  vertex_to_faces_ptrs,
  gface_to_vertices_data,
  gface_to_vertices_ptrs)

@test gface_to_face == [1,4,2]

end # module KernelsTests
