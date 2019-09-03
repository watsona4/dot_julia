import Base: getindex, setindex!, copy

mutable struct Board
    data::Array{Int}
    score::Int
    level::Int
    lines_to_goal::Int
    tile::Tile
    location::Vector{Int}
    orientation::Int
    nexttiles::Vector{Tile}
    holdtile::Tile
    allowhold::Bool
end
Board(i=0) = Board(ones(Int, 20, 10)*i, 0, 1+i, 5,
            rand(Tiles)(), [4,1], 0,
            [rand(Tiles)() for i in 1:3], rand(Tiles)(), true)

copy(b::Board) = Board(copy(b.data), b.score, b.level, b.lines_to_goal,
                    b.tile, b.location, b.orientation,
                    copy(b.nexttiles), b.holdtile, b.allowhold)

function getindex(b::Board)
    dy,dx = size(rotatedtile(b)) .-1
    x,y = b.location
    return b.data[y:y+dy, x:x+dx]
end

function setindex!(b::Board, s::AbstractArray)
    dy,dx = size(rotatedtile(b)) .-1
    x,y = b.location
    b.data[y:y+dy, x:x+dx] = s
end

rotatedtile(b::Board) = rotr90(data(b.tile), b.orientation)

function nexttile!(b::Board)
    push!(b.nexttiles, rand(Tiles)())
    b.tile = popfirst!(b.nexttiles)
end

function add_tile!(b::Board)
    nexttile!(b)
    b.location = start_location(b.tile)
    b.orientation = 0
    if all(b[] .== 0)
        oldboard = copy(b)
        b[] += data(b.tile)
        update_board!(oldboard, b)
        return true
    end
    false
end

function delete_lines!(b::Board)
    oldboard = copy(b)
    nr_lines = 0
    for i in 1:20
        if all(b.data[i, :] .!= 0)
            b.data[2:i, :] = b.data[1:i-1, :]
            b.data[1,:] .= 0
            nr_lines += 1
        end
    end
    b.lines_to_goal -= nr_lines
    b.score += [0 1 3 5 8][nr_lines+1] * b.level * 100
    if b.lines_to_goal ≤ 0
        b.level += 1
        b.lines_to_goal += b.level*5
    end
    update_board!(oldboard, b)
end
