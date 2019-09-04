module FactoriesTests

using Test
using UnstructuredGrids.Core
using UnstructuredGrids.Kernels
using UnstructuredGrids.Factories
using UnstructuredGrids.RefCellGallery
using UnstructuredGrids.VTK

grid = UGrid(domain=(0,1,-1,0),partition=(2,2))

@test isa(grid,UGrid)

p = [0.0 1.0 2.0 0.0 1.0 2.0 0.0 1.0 2.0;
     -1.0 -1.0 -1.0 -0.5 -0.5 -0.5 0.0 0.0 0.0] 

clist = [1, 2, 4, 5, 2, 3, 5, 6, 4, 5, 7, 8, 5, 6, 8, 9]
cptrs = [1, 5, 9, 13, 17]

@test coordinates(grid) ≈ p
@test list(connections(grid)) == clist
@test ptrs(connections(grid)) == cptrs
@test celltypes(grid) == ones(Int,length(cptrs)-1)

grid = UGrid(domain=(0,1,-1,0,2,4),partition=(1,2,3))

p = [0.0 1.0 0.0 1.0 0.0 1.0 0.0 1.0 0.0 1.0 0.0 1.0 0.0 1.0 0.0 1.0 0.0 1.0 0.0 1.0 0.0 1.0 0.0 1.0;
     -1.0 -1.0 -0.5 -0.5 0.0 0.0 -1.0 -1.0 -0.5 -0.5 0.0 0.0 -1.0 -1.0 -0.5 -0.5 0.0 0.0 -1.0 -1.0 -0.5 -0.5 0.0 0.0;
     2.0 2.0 2.0 2.0 2.0 2.0 2.5 2.5 2.5 2.5 2.5 2.5 3.0 3.0 3.0 3.0 3.0 3.0 3.5 3.5 3.5 3.5 3.5 3.5]

clist = [
  1, 2, 3, 4, 7, 8, 9, 10, 3, 4, 5, 6, 9, 10, 11,
  12, 7, 8, 9, 10, 13, 14, 15, 16, 9, 10, 11, 12,
  15, 16, 17, 18, 13, 14, 15, 16, 19, 20, 21, 22,
  15, 16, 17, 18, 21, 22, 23, 24]

cptrs = [1, 9, 17, 25, 33, 41, 49]

@test coordinates(grid) ≈ p
@test list(connections(grid)) == clist
@test ptrs(connections(grid)) == cptrs
@test celltypes(grid) == ones(Int,length(cptrs)-1)


grid = UGrid(domain=(0,1,0,1),partition=(2,2))

ltcell_to_lpoints = [[1,2,3],[4,3,2]]

tgrid = UGrid(grid,ltcell_to_lpoints,TRIANGLE)

@test coordinates(grid) === coordinates(tgrid)

clist = [1, 2, 4, 5, 4, 2, 2, 3, 5, 6, 5, 3, 4, 5, 7, 8, 7, 5, 5, 6, 8, 9, 8, 6]
cptrs = [1, 4, 7, 10, 13, 16, 19, 22, 25]

@test list(connections(tgrid)) == clist
@test ptrs(connections(tgrid)) == cptrs
@test celltypes(tgrid) == ones(Int,length(cptrs)-1)

ltcell_to_lpoints = [
 [7,3,2,1], [7,5,2,1], [7,4,3,2], [7,4,8,2], [7,6,5,2], [7,6,8,2]]

grid = UGrid(domain=(0,1,0,1,0,1),partition=(2,2,3))

tgrid = UGrid(grid,ltcell_to_lpoints,TETRAHEDRON)


D = 1

grid = UGrid(domain=(0,1,0,1),partition=(2,2))

ltcell_to_lnodes = [[1,2,3],[4,3,2]]
tgrid = UGrid(grid,ltcell_to_lnodes,TRIANGLE)

cell_to_faces = generate_cell_to_faces(D,grid)
tcell_to_tfaces = generate_cell_to_faces(D,tgrid)

refcell = grid.refcells[1]
reftcell = tgrid.refcells[1]

ltface_to_ltnodes = reftcell.faces[D+1]
lface_to_lnodes = refcell.faces[D+1]

ntfaces = maximum(tcell_to_tfaces.list)

tface_to_face = generate_tface_to_face(
  cell_to_faces.list,
  cell_to_faces.ptrs,
  tcell_to_tfaces.list,
  tcell_to_tfaces.ptrs,
  ltcell_to_lnodes,
  ltface_to_ltnodes,
  lface_to_lnodes,
  ntfaces)

@test tface_to_face == [1, 0, 3, 2, 4, 5, 0, 6, 7, 0, 9, 8, 10, 0, 11, 12]

end # module FactoriesTests
