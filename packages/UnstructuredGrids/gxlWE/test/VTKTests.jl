module VTKTests

using Test
using UnstructuredGrids.VTK
using UnstructuredGrids.Core
using UnstructuredGrids.Factories
using UnstructuredGrids.RefCellGallery: LEX_HEXAHEDRON

d = mktempdir()
f = joinpath(d,"grid")

grid = UGrid(domain=(0,1,-1,0),partition=(2,2))

writevtk(grid,f)

grid = UGrid(domain=(0,1,-1,0,2,4),partition=(2,3,4))

writevtk(grid,f)

fgrid = UGrid(grid,2)

writevtk(fgrid,f)

fgrid = UGrid(grid,1)

writevtk(fgrid,f)

writevtk(LEX_HEXAHEDRON,f)

rm(d,recursive=true)

end # module VTKTests
