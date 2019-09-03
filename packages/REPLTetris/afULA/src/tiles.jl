abstract type Tile end
start_location(::Tile) = [4,1]

struct L <: Tile end
data(tile::L) = [0 0 1; 1 1 1] * 2  # orange

struct J <: Tile end
data(tile::J) = [1 0 0; 1 1 1] * 6  # blue

struct S <: Tile end
data(tile::S) = [0 1 1; 1 1 0] * 4  # green

struct Z <: Tile end
data(tile::Z) = [1 1 0; 0 1 1] * 1  # red

struct T <: Tile end
data(tile::T) = [1 1 1; 0 1 0] * 7  # magenta

struct I <: Tile end
data(tile::I) = [1 1 1 1] * 5       # cyan
start_location(::I) = [4,2]

struct O <: Tile end
data(tile::O) = [1 1; 1 1] * 3      # yellow
start_location(::O) = [5,1]

const Tiles = [T, L, J, S, Z, I, O]
