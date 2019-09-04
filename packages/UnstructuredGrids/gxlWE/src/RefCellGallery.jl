module RefCellGallery

using UnstructuredGrids.Core

export SEGMENT
export TRIANGLE
export SQUARE
export LEX_SQUARE
export LEX_HEXAHEDRON
export TETRAHEDRON

const SEGMENT = RefCell(
  ndims = 1,
  faces = [ [[1],[2]] ],
  facetypes = [ [1,1] ],
  reffaces = [ [VERTEX] ],
  coordinates = Float64[-1 1;],
  vtkid = 3,
  vtknodes = [1,2] )

const TRIANGLE = RefCell(
  ndims = 2,
  faces = [ [[1],[2],[3]], [[1,2],[2,3],[3,1]] ],
  facetypes = [ [1,1,1], [1,1,1] ],
  reffaces = [ [VERTEX], [SEGMENT] ],
  coordinates = Float64[ 0 1 0; 0 0 1],
  vtkid = 5,
  vtknodes = [1,2,3])

const TETRAHEDRON = RefCell(
  ndims = 3,
  faces = [
    [[1],[2],[3],[4]],
    [[1,2],[1,3],[1,4],[2,3],[2,4],[3,4]],
    [[1,3,2],[1,2,4],[1,4,3],[2,3,4]] ],
  facetypes = [ [1,1,1,1], [1,1,1,1,1,1], [1,1,1,1] ],
  reffaces = [ [VERTEX], [SEGMENT], [TRIANGLE] ],
  coordinates = Float64[ 0 1 0 0; 0 0 1 0; 0 0 0 1],
  vtkid = 10,
  vtknodes = [1,2,3,4])

const SQUARE = RefCell(
  ndims = 2,
  faces = [ [[1],[2],[3],[4]], [[1,2],[2,3],[3,4],[4,1]] ],
  facetypes = [ [1,1,1,1], [1,1,1,1] ],
  reffaces = [ [VERTEX], [SEGMENT] ],
  coordinates = Float64[ -1 1 1 -1; -1 -1 1 1],
  vtkid = 9,
  vtknodes = [1,2,3,4])

const LEX_SQUARE = RefCell(
  ndims = 2,
  faces = [ [[1],[2],[3],[4]], [[1,2],[3,4],[1,3],[2,4]] ],
  facetypes = [ [1,1,1,1], [1,1,1,1] ],
  reffaces = [ [VERTEX], [SEGMENT] ],
  coordinates = Float64[ -1 1 -1 1; -1 -1 1 1],
  vtkid = 9,
  vtknodes = [1,2,4,3])

const LEX_HEXAHEDRON = RefCell(
  ndims = 3,
  faces = [
    [[1],[2],[3],[4],[5],[6],[7],[8]],
    [[1,2],[3,4],[1,3],[2,4],[5,6],[7,8],[5,7],[6,8],[1,5],[2,6],[3,7],[4,8]],
    [[1,2,3,4],[5,6,7,8],[1,2,5,6],[3,4,7,8],[1,3,5,7],[2,4,6,8]]],
  facetypes = [ fill(1,8), fill(1,12), fill(1,6) ],
  reffaces = [ [VERTEX], [SEGMENT], [LEX_SQUARE] ],
  coordinates = Float64[ -1 1 -1 1 -1 1 -1 1; -1 -1 1 1 -1 -1 1 1; -1 -1 -1 -1 1 1 1 1],
  vtkid = 12,
  vtknodes = [1,2,4,3,5,6,8,7])

end # module RefCellGallery
