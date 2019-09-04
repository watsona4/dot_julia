module Factories

using UnstructuredGrids.Helpers
using UnstructuredGrids.Kernels
using UnstructuredGrids.Core
using UnstructuredGrids.RefCellGallery

# **DISCLAIMER**
# This library is not supposed to be a mesh generator.
# The following mesh generation routines are mainly for
# testing purposes.

import UnstructuredGrids.Core: UGrid

function UGrid(;domain,partition)
  _cartesian_grid(domain,partition)
end

function UGrid(
  grid::UGrid,
  ltcell_to_lpoints::Vector{Vector{Int}},
  refsubcell::RefCell)
  _refine_grid(grid,ltcell_to_lpoints,refsubcell)
end

# Helpers

function _cartesian_grid(domain,partition)
  refcell = _cartesian_grid_refcell(partition)
  points, celldata, cellptrs, celltypes, refcells = _cartesian_allocate(partition,refcell)
  _cartesian_fill_points!(points,domain,partition)
  _cartesian_fill_cells!(celldata,partition)
  UGrid(celldata,cellptrs,celltypes,refcells,points)
end

function _cartesian_allocate(partition::NTuple{D,Int},refcell) where D
  ncells = prod(partition)
  npoints = prod([ n+1 for n in partition])
  n = 2^D
  points = Array{Float64,2}(undef,(D,npoints))
  celltypes = ones(Int,ncells)
  cellptrs = fill(n,ncells+1)
  length_to_ptrs!(cellptrs)
  celldata = Vector{Int}(undef,n*ncells)
  refcells = [refcell]
  (points,celldata,cellptrs,celltypes,refcells)
end

_cartesian_grid_refcell(partition) = @notimplemented

function _cartesian_grid_refcell(partition::NTuple{2,Int})
  LEX_SQUARE
end

function _cartesian_grid_refcell(partition::NTuple{3,Int})
  LEX_HEXAHEDRON
end

_cartesian_fill_points!(points,domain,partition) = @notimplemented

function _cartesian_fill_points!(points,domain,partition::NTuple{2,Int})
  ncx = partition[1]
  ncy = partition[2]
  x0 = domain[1]
  x1 = domain[2]
  y0 = domain[3]
  y1 = domain[4]
  dx = x1-x0/ncx
  dy = y1-y0/ncy
  p = 1
  for j in 1:ncy+1
    for i in 1:ncx+1
      points[1,p] = x0 + (i-1)*dx
      points[2,p] = y0 + (j-1)*dy
      p += 1
    end
  end
end

function _cartesian_fill_points!(points,domain,partition::NTuple{3,Int})
  ncx = partition[1]
  ncy = partition[2]
  ncz = partition[3]
  x0 = domain[1]
  x1 = domain[2]
  y0 = domain[3]
  y1 = domain[4]
  z0 = domain[5]
  z1 = domain[6]
  dx = x1-x0/ncx
  dy = y1-y0/ncy
  dz = z1-z0/ncz
  p = 1
  for k in 1:ncz+1
    for j in 1:ncy+1
      for i in 1:ncx+1
        points[1,p] = x0 + (i-1)*dx
        points[2,p] = y0 + (j-1)*dy
        points[3,p] = z0 + (k-1)*dy
        p += 1
      end
    end
  end
end

_cartesian_fill_cells!(celldata,partition) = @notimplemented

function _cartesian_fill_cells!(celldata,partition::NTuple{2,Int})
  ncx = partition[1]
  ncy = partition[2]
  p = 1
  for j in 1:ncy
    for i in 1:ncx
      for b in 0:1
        for a in 0:1
          celldata[p] =  i+a + (j+b-1)*(ncx+1)
          p += 1
        end
      end
    end
  end
end

function _cartesian_fill_cells!(celldata,partition::NTuple{3,Int})
  ncx = partition[1]
  ncy = partition[2]
  ncz = partition[3]
  p = 1
  for k in 1:ncz
    for j in 1:ncy
      for i in 1:ncx
        for c in 0:1
          for b in 0:1
            for a in 0:1
              celldata[p] =  i+a + (j+b-1)*(ncx+1) + (k+c-1)*(ncx+1)*(ncy+1)
              p += 1
            end
          end
        end
      end
    end
  end
end

function _refine_grid(grid::UGrid,ltcell_to_lpoints,refsimplex)

  @assert length(grid.refcells) == 1
 
  coords = grid.coordinates
  cells_data = grid.cells.list
  cells_ptrs = grid.cells.ptrs
  cell_types = grid.celltypes

  tcells_data, tcells_ptrs = refine_grid_connectivity(
    cells_data, cells_ptrs, ltcell_to_lpoints)

  ntcells = length(tcells_ptrs) -1
  tcell_types = fill(1,ntcells)

  UGrid(tcells_data,tcells_ptrs,tcell_types,[refsimplex,],coords)

end

end # module Factories
