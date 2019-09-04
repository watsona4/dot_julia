# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] - 2019-05-13
### Added
- Added `generate_grid_graph` and `generate_full_grid_graph`
- Exporting more names at the top level
- Changelog

### Changed
- Replaced `generate_cell_to_faces_from_face` -> `find_cell_to_faces`

## [0.1.1] - 2019-05-04
### Added
- Basic structs: UGrid, Connections, and RefCell
- Find the lower dimensial objects (e.g., edges and faces) on the boundary of each cell in the grid
- Find the vertices on low dimensional objects of the grid (e.g., the vertices on each face, the vertices on each edge)
- Find dual connections (e.g., cells arround a face, cells around a vertex, faces around an edge, etc.)
- Identify objects on the boundary of the grid
- Export UGrid and RefCellObjects into `.vtu` files (using the `WriteVTK` package).
- Cartesian grid generator in 2d and 3d
