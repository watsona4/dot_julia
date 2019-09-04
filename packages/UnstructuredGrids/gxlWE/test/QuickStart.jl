
#Pkg.add("UnstructuredGrids")
using UnstructuredGrids

# Generate a grid from its nodal coordinates, cell connectivities,
# and cell types

# Define coordinates
coords = zeros(2,9)
coords[:,1] = [1,1]
coords[:,2] = [3,1]
coords[:,3] = [4,1]
coords[:,4] = [1,2]
coords[:,5] = [2,2]
coords[:,6] = [1,3]
coords[:,7] = [2,3]
coords[:,8] = [3,3]
coords[:,9] = [4,3]

# Define connectivity
connect = [1,2,5,4,2,3,9,4,5,7,6,5,8,7,5,2,8,2,9,8]
offsets = [1,      5,    8,      12,   15,   18,   21]

# Define cell types
using UnstructuredGrids.RefCellGallery: SQUARE, TRIANGLE
refcells = [SQUARE, TRIANGLE]
types = [1,2,1,2,2,2]

# Generate the UGrid object
grid = UGrid(connect,offsets,types,refcells,coords)

# Export grid into vtk format
#writevtk(grid,"grid")

# Generate a global numbering for the edges (1d objects) of the grid,
# and find which edges are on the boundary of each cell
n=1
cell_to_edges = generate_cell_to_faces(n,grid)

#@show cell_to_edges.list
#@show cell_to_edges.ptrs

cell = 3
a = cell_to_edges.ptrs[cell]
b = cell_to_edges.ptrs[cell+1]-1
edges = cell_to_edges.list[a:b]
#@show edges







# Generate a toy structured grid of the unit cube
# with 2x3x2 quadrilateral cells
grid = UGrid(domain=(0,1,0,1,0,1),partition=(2,3,2))

# Get the connectivity of the cells of the grid (i.e., for each cell, the ids of its vertices)
cell_to_vertices = connections(grid)

# The cell connectivity is represented by a `Connections` object
@assert isa(cell_to_vertices, Connections)

# `Connections` is a struct representing a vector of vectors
# in compressed form. It is fully described by a vector containing
# the flatted underlying data and another vector containing
# the start and end of each of the sub-vectors.
# That is:

cell_to_vertices_data = list(cell_to_vertices)
cell_to_vertices_ptrs = ptrs(cell_to_vertices)

cell = 2
ibeg = cell_to_vertices_ptrs[cell]
iend = cell_to_vertices_ptrs[cell+1]-1
vertices = cell_to_vertices_data[ibeg:iend] # Vertices of cell 2
@assert vertices == [2, 3, 5, 6, 14, 15, 17, 18]

# Get the coordinates of the mesh vertices
vertex_to_coords = coordinates(grid)
@assert isa(vertex_to_coords, Array{Float64,2})

# First axis for space dimensions, second one for number of vertices
@assert size(vertex_to_coords) == (3,36)

# Find cells around each vertex
vertex_to_cells = generate_dual_connections(cell_to_vertices)

# The returned data is a vector of vectors represented by a Connections object
@assert isa(vertex_to_cells, Connections)

# Generate a global numbering for the edges (1d objects) of the grid,
# and find which edges are on the boundary of each cell
n=1
cell_to_edges = generate_cell_to_faces(n,grid)

# The returned data again a Connections object
@assert isa(cell_to_edges, Connections)

# Idem for faces (2d objects)
n=2
cell_to_faces = generate_cell_to_faces(n,grid)
@assert isa(cell_to_faces, Connections)



