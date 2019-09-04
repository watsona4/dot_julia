module VTK

using WriteVTK
using WriteVTK.VTKCellTypes: VTK_VERTEX
using WriteVTK.VTKCellTypes: VTK_LINE
using WriteVTK.VTKCellTypes: VTK_TRIANGLE
using WriteVTK.VTKCellTypes: VTK_QUAD
using WriteVTK.VTKCellTypes: VTK_TETRA
using WriteVTK.VTKCellTypes: VTK_HEXAHEDRON

using UnstructuredGrids.Core

export writevtk

function writevtk(grid::UGrid,filebase;celldata=Dict(),pointdata=Dict())
  points = coordinates(grid)
  cells = _vtkcells(grid)
  vtkfile = vtk_grid(filebase, points, cells, compress=false)
  for (k,v) in celldata
    vtk_cell_data(vtkfile,_prepare_data(v),k)
  end
  for (k,v) in pointdata
    vtk_point_data(vtkfile,_prepare_data(v),k)
  end
  outfiles = vtk_save(vtkfile)
end

function writevtk(r::RefCell,filebase)
  for d in 0:(ndims(r)-1)
    f = "$(filebase)_$d"
    grid = UGrid(r,dim=d)
    writevtk(grid,f)
  end
end

_prepare_data(v) = v

function _prepare_data(v::AbstractVector{Bool})
  b = similar(v,Int)
  b .= 0
  b[v] .= 1
  b
end

function _vtkcells(grid::UGrid)
  vtkid_to_vtktype = _vtkcelltypedict()
  cell_to_ctype = celltypes(grid)
  cell_to_points_data = list(connections(grid))
  cell_to_points_ptrs = ptrs(connections(grid))
  ctype_to_refcell = refcells(grid)
  ctype_to_vtkid = [ vtkid(rc) for rc in ctype_to_refcell ]
  ctype_to_vtknodes = [ vtknodes(rc) for rc in ctype_to_refcell ]
  ncells = length(cell_to_ctype)
  vtkcells = Array{MeshCell}(undef,(ncells))
  for cell in 1:ncells
    a = cell_to_points_ptrs[cell]
    b = cell_to_points_ptrs[cell+1]-1
    cellpoints = cell_to_points_data[a:b]
    ctype = cell_to_ctype[cell]
    vtkid = ctype_to_vtkid[ctype]
    vtknodes = ctype_to_vtknodes[ctype]
    vtktype = vtkid_to_vtktype[vtkid]
    vtkcells[cell] = MeshCell(vtktype,cellpoints[vtknodes])
  end
  vtkcells
end

function _vtkcelltypedict()
  d = Dict{Int,WriteVTK.VTKCellTypes.VTKCellType}()
  d[VTK_VERTEX.vtk_id] = VTK_VERTEX
  d[VTK_LINE.vtk_id] = VTK_LINE
  d[VTK_LINE.vtk_id] = VTK_LINE
  d[VTK_TRIANGLE.vtk_id] = VTK_TRIANGLE
  d[VTK_QUAD.vtk_id] = VTK_QUAD
  d[VTK_TETRA.vtk_id] = VTK_TETRA
  d[VTK_HEXAHEDRON.vtk_id] = VTK_HEXAHEDRON
  d
end

end #module VTK
