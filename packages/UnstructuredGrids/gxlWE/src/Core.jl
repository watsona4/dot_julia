module Core

using UnstructuredGrids.Helpers
using UnstructuredGrids.Kernels

import Base: ndims
import Base: show
import Base: ==
import UnstructuredGrids.Kernels: generate_dual_connections
import UnstructuredGrids.Kernels: generate_cell_to_faces
import UnstructuredGrids.Kernels: find_cell_to_faces
import UnstructuredGrids.Kernels: generate_face_to_ftype
import UnstructuredGrids.Kernels: generate_face_to_vertices
import UnstructuredGrids.Kernels: generate_facet_to_isboundary
import UnstructuredGrids.Kernels: generate_face_to_isboundary

export Connections
export RefCell
export UGrid
export VERTEX
export list
export ptrs
export coordinates
export connections
export reffaces
export facetypes
export vtkid
export vtknodes
export celltypes
export refcells
export generate_ftype_to_refface
export generate_grid_graph
export generate_full_grid_graph


struct Connections{L<:AbstractVector{<:Integer},P<:AbstractVector{<:Integer}}
  list::L
  ptrs::P
end

list(c::Connections) = c.list

ptrs(c::Connections) = c.ptrs

function Connections(c::AbstractVector{<:AbstractVector{<:Integer}})
  list, ptrs = generate_data_and_ptrs(c)
  Connections(list,ptrs)
end

function show(io::IO,c::Connections)
  clist = list(c)
  cptrs = ptrs(c)
  ncells = length(cptrs)-1
  for cell in 1:ncells
    a = cptrs[cell]
    b = cptrs[cell+1]-1
    println(io,"$cell -> $(clist[a:b])")
  end
end

function (==)(a::Connections,b::Connections)
  a.list == b.list && a.ptrs == b.ptrs
end

struct RefCell
  ndims::Int
  faces::Vector{Vector{Vector{Int}}}
  facetypes::Vector{Vector{Int}}
  reffaces::Vector{Vector{RefCell}}
  coordinates::Array{Float64,2}
  vtkid::Int
  vtknodes::Vector{Int}
end

ndims(r::RefCell) = r.ndims

connections(r::RefCell, dim::Integer) =r.faces[dim+1]

facetypes(r::RefCell, dim::Integer) = r.facetypes[dim+1]

reffaces(r::RefCell, dim::Integer) =r.reffaces[dim+1]

coordinates(r::RefCell) = r.coordinates

vtkid(r::RefCell) = r.vtkid

vtknodes(r::RefCell) = r.vtknodes

function RefCell(;
  ndims::Int,
  faces::Vector{Vector{Vector{Int}}},
  facetypes::Vector{Vector{Int}} = fill(Int[],ndims),
  reffaces::Vector{Vector{RefCell}} = fill(RefCell[],ndims),
  coordinates::Array{Float64,2} = zeros(ndims,0),
  vtkid::Int = UNSET,
  vtknodes::Vector{Int} = Int[])

  @assert ndims == length(faces)
  @assert ndims == length(facetypes)
  @assert ndims == length(reffaces)
  @assert ndims == size(coordinates,1)

  RefCell( ndims, faces, facetypes, reffaces, coordinates, vtkid, vtknodes)

end

const VERTEX = RefCell(
  ndims = 0, faces = fill([Int[]],0), vtkid = 1, vtknodes = [1] )

struct UGrid{
  C<:Connections,
  T<:AbstractVector{<:Integer},
  X<:AbstractArray{<:Number,2}}

  cells::C
  celltypes::T
  refcells::Vector{RefCell}
  coordinates::X

end

connections(g::UGrid) = g.cells

celltypes(g::UGrid) = g.celltypes

refcells(g::UGrid) = g.refcells

coordinates(g::UGrid) = g.coordinates

function ndims(g::UGrid)
  maximum((ndims(r) for r in refcells(g)))
end

function refconnections(g::UGrid,dim::Integer)
  refconnections(refcells(g),dim)
end

function refconnections(refcells::Vector{RefCell}, dim::Integer)
  [ connections(refcell,dim) for refcell in refcells ]
end

function UGrid( cellsdata, cellsptrs, celltypes, refcells, coordinates)
  cells = Connections(cellsdata, cellsptrs)
  UGrid( cells, celltypes, refcells, coordinates)
end

function UGrid(r::RefCell;dim::Integer)
  cells = connections(r,dim)
  celltypes = facetypes(r,dim)
  refcells = reffaces(r,dim)
  coords = coordinates(r)
  UGrid( Connections(cells), celltypes, refcells, coords)
end

function UGrid(
  grid::UGrid,
  dim::Integer,
  vertex_to_cells=generate_dual_connections(connections(grid)),
  cell_to_faces=generate_cell_to_faces(dim,grid,vertex_to_cells))
  cell_to_vertices = connections(grid)
  cell_to_ctype = celltypes(grid)
  ctype_to_refcell = refcells(grid)
  ftype_to_refface, ctype_to_lface_to_ftype = generate_ftype_to_refface(dim,ctype_to_refcell)
  face_to_ftype = generate_face_to_ftype(
    cell_to_faces, cell_to_ctype, ctype_to_lface_to_ftype)
  face_to_vertices = generate_face_to_vertices(
    dim, cell_to_vertices, cell_to_faces, cell_to_ctype, ctype_to_refcell)
  point_to_coords = coordinates(grid)
  UGrid(face_to_vertices, face_to_ftype, ftype_to_refface, point_to_coords)
end


function generate_dual_connections(cell_to_faces::Connections)
  cell_to_faces_data = list(cell_to_faces)
  cell_to_faces_ptrs = ptrs(cell_to_faces)
  face_to_cells_data, face_to_cells_ptrs = generate_dual_connections(
  cell_to_faces_data, cell_to_faces_ptrs)
  Connections(face_to_cells_data, face_to_cells_ptrs)
end

function generate_cell_to_faces(
  dim::Integer,
  grid::UGrid,
  vertex_to_cells=generate_dual_connections(connections(grid)))
  cell_to_vertices = connections(grid)
  cell_to_ctype = celltypes(grid)
  ctype_to_refcell = refcells(grid)
  cell_to_faces = generate_cell_to_faces(
      cell_to_vertices, vertex_to_cells, cell_to_ctype, ctype_to_refcell,dim)
  cell_to_faces
end

function generate_cell_to_faces(
  cell_to_vertices::Connections,
  vertex_to_cells::Connections,
  cell_to_ctype::AbstractVector{<:Integer},
  ctype_to_refcell::Vector{RefCell},
  dim::Integer)

  cell_to_vertices_data = list(cell_to_vertices)
  cell_to_vertices_ptrs = ptrs(cell_to_vertices)

  vertex_to_cells_data = list(vertex_to_cells)
  vertex_to_cells_ptrs = ptrs(vertex_to_cells)

  ctype_to_lface_to_lvertices = refconnections(ctype_to_refcell, dim)

  cell_to_faces_data, cell_to_faces_ptrs = generate_cell_to_faces(
    cell_to_vertices_data,
    cell_to_vertices_ptrs,
    ctype_to_lface_to_lvertices,
    cell_to_ctype,
    vertex_to_cells_data,
    vertex_to_cells_ptrs)

  Connections(cell_to_faces_data, cell_to_faces_ptrs)

end

function find_cell_to_faces(
  cell_to_vertices::Connections,
  vertex_to_faces::Connections,
  cell_to_ctype::AbstractVector{<:Integer},
  ctype_to_refcell::Vector{RefCell},
  dim::Integer)

  cell_to_vertices_data = list(cell_to_vertices)
  cell_to_vertices_ptrs = ptrs(cell_to_vertices)

  vertex_to_faces_data = list(vertex_to_faces)
  vertex_to_faces_ptrs = ptrs(vertex_to_faces)

  ctype_to_lface_to_lvertices = refconnections( ctype_to_refcell, dim)

  cell_to_faces_data, cell_to_faces_ptrs = find_cell_to_faces(
    cell_to_vertices_data,
    cell_to_vertices_ptrs,
    ctype_to_lface_to_lvertices,
    cell_to_ctype,
    vertex_to_faces_data,
    vertex_to_faces_ptrs)

  Connections(cell_to_faces_data, cell_to_faces_ptrs)

end

function find_cell_to_faces(grid::UGrid, fgrid::UGrid)
  face_to_vertices = connections(fgrid)
  vertex_to_faces = generate_dual_connections(face_to_vertices)
  dim = ndims(fgrid)
  find_cell_to_faces(grid, vertex_to_faces, dim)
end

function find_cell_to_faces(
  grid::UGrid,
  vertex_to_faces::Connections,
  dim::Integer)

  cell_to_vertices = connections(grid)
  cell_to_ctype = celltypes(grid)
  ctype_to_refcell = refcells(grid)
  find_cell_to_faces(
    cell_to_vertices,
    vertex_to_faces,
    cell_to_ctype,
    ctype_to_refcell,
    dim)
end

function generate_face_to_vertices(
  dim::Integer,
  cell_to_vertices::Connections,
  cell_to_faces::Connections,
  cell_to_ctype::AbstractVector{<:Integer},
  ctype_to_refcell::Vector{RefCell})


  ctype_to_lface_to_lvertices = refconnections( ctype_to_refcell, dim)

  l, p = generate_face_to_vertices(
    list(cell_to_vertices),
    ptrs(cell_to_vertices),
    list(cell_to_faces),
    ptrs(cell_to_faces),
    cell_to_ctype,
    ctype_to_lface_to_lvertices)

  Connections(l,p)

end


function generate_face_to_ftype(
  cell_to_faces::Connections,
  cell_to_ctype::AbstractVector{<:Integer},
  ctype_to_lface_to_ftype::AbstractVector{<:AbstractVector{<:Integer}})
  generate_face_to_ftype(
    list(cell_to_faces),
    ptrs(cell_to_faces),
    cell_to_ctype,
    ctype_to_lface_to_ftype)
end

function generate_ftype_to_refface(dim,ctype_to_refcell)

  i_to_refface = Vector{RefCell}(undef,0)
  nctypes = length(ctype_to_refcell)
  ctype_to_lftype_to_i = Vector{Vector{Int}}(undef,nctypes)

  i = 1
  for (ctype,refcell) in enumerate(ctype_to_refcell)
    lftype_to_refface = reffaces(refcell,dim)
    lftype_to_i = Vector{Int}(undef,length(lftype_to_refface))
    for (lftype,refface) in enumerate(lftype_to_refface)
      push!(i_to_refface,refface)
      lftype_to_i[lftype] = i
      i +=1
    end
    ctype_to_lftype_to_i[ctype] = lftype_to_i
  end

  ftype_to_refface = unique(i_to_refface)
  i_to_ftype = indexin(i_to_refface,ftype_to_refface)

  ctype_to_lftype_to_ftype = copy(ctype_to_lftype_to_i)
  for ctype in 1:length(ctype_to_lftype_to_i)
    for lftype in 1:length(ctype_to_lftype_to_i[ctype])
      i = ctype_to_lftype_to_i[ctype][lftype]
      ftype = i_to_ftype[i]
      ctype_to_lftype_to_ftype[ctype][lftype] = ftype
    end
  end

  ctype_to_lface_to_ftype = Vector{Vector{Int}}(undef,nctypes)
  for (ctype,refcell) in enumerate(ctype_to_refcell)
    lface_to_lftype = facetypes(refcell,dim)
    lftype_to_ftype = ctype_to_lftype_to_ftype[ctype]
    lface_to_ftype = lftype_to_ftype[lface_to_lftype]
    ctype_to_lface_to_ftype[ctype] = lface_to_ftype
  end

  (ftype_to_refface, ctype_to_lface_to_ftype)

end

function generate_facet_to_isboundary(face_to_cells::Connections)
  face_to_cells_ptrs = ptrs(face_to_cells)
  generate_facet_to_isboundary(face_to_cells_ptrs)
end

function generate_face_to_isboundary(
  facet_to_isboundary::AbstractVector{Bool},
  face_to_facets::Connections)

  face_to_facets_data = list(face_to_facets)
  face_to_facets_ptrs = ptrs(face_to_facets)

  generate_face_to_isboundary(
    facet_to_isboundary,
    face_to_facets_data,
    face_to_facets_ptrs)

end

function generate_grid_graph(grid::UGrid)

  D = ndims(grid)
  cell_to_vertices = connections(grid)
  vertex_to_cells = generate_dual_connections(cell_to_vertices)

  T = typeof(cell_to_vertices)
  primal = Vector{T}(undef,D+1)
  dual = Vector{T}(undef,D+1)

  d = 0
  primal[d+1] = cell_to_vertices
  dual[d+1] = vertex_to_cells

  for d in 1:(D-1)
    cell_to_dfaces = generate_cell_to_faces( d, grid, vertex_to_cells)
    dfaces_to_cells = generate_dual_connections(cell_to_dfaces)
    primal[d+1] = cell_to_dfaces
    dual[d+1] = dfaces_to_cells
  end

  (primal, dual)

end

function generate_full_grid_graph(grid::UGrid)

  D = ndims(grid)
  data = Array{Connections}(undef,D+1,D+1)

  primal, dual = generate_grid_graph(grid)
  for d in 0:(D-1)
    data[D+1,d+1] = primal[d+1]
    data[d+1,D+1] = dual[d+1]
  end

  fgrids = [ UGrid(grid,d,dual[0+1],primal[d+1]) for d in 1:(D-1)]
  for d in 1:(D-1)
    fgrid = fgrids[d]
    face_to_vertices = connections(fgrid)
    vertex_to_faces = generate_dual_connections(face_to_vertices)
    data[d+1,0+1] = face_to_vertices
    data[0+1,d+1] = vertex_to_faces
  end

  for d in 1:(D-1)
    fgrid = fgrids[d]
    for j in 1:(d-1)
      vertex_to_jfaces = data[0+1,j+1]
      face_to_jfaces = find_cell_to_faces(fgrid, vertex_to_jfaces, j)
      jface_to_faces = generate_dual_connections(face_to_jfaces)
      data[d+1,j+1] = face_to_jfaces
      data[j+1,d+1] = jface_to_faces
    end
  end

  for d in 0:(D-1)
    dfaces_to_cells = data[d+1,D+1]
    data[d+1,d+1] = _identity_connections(dfaces_to_cells)
  end

  cell_to_vertices = data[D+1,0+1]
  data[D+1,D+1] = _identity_connections(cell_to_vertices)

  data

end

function _identity_connections(dfaces_to_cells)
    ndfaces = length(dfaces_to_cells.ptrs)-1
    Connections( [i for i in 1:ndfaces], [i for i in 1:(ndfaces+1)])
end

# Helpers

end # module Core
