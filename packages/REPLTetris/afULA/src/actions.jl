function checkcollision(b::Board)
    x,y = b.location
    dy, dx = size(rotatedtile(b)) .-1
    x+dx <= 10 && x >= 1 && y+dy <= 20 && !any((b[] .!= 0 ) .& (rotatedtile(b) .!= 0))
end

function affine!(b::Board, rotation=0, translation=[0,0])
    oldboard = copy(b)

    b[] -= rotatedtile(b)
    b.orientation -= rotation
    b.location += translation
    if checkcollision(b)
        b[] += rotatedtile(b)
        update_board!(oldboard, b)
        return true
    end
    b.orientation += rotation
    b.location -= translation
    b[] += rotatedtile(b)
    return false
end

rot_right!(b::Board)  = affine!(b, -1, [ 0, 0])
rot_left!(b::Board)   = affine!(b,  1, [ 0, 0])
move_right!(b::Board) = affine!(b,  0, [ 1, 0])
move_left!(b::Board)  = affine!(b,  0, [-1, 0])
drop!(b::Board)       = affine!(b,  0, [ 0, 1])
fast_drop!(b::Board)  = (while drop!(b) end; return false)

function hold!(b::Board)
    if b.allowhold
        oldboard = copy(b)

        b[] -= rotatedtile(b)
        b.tile, b.holdtile = b.holdtile, b.tile
        b.orientation = 0
        b.location = start_location(b.tile)
        b[] += rotatedtile(b)
        print_hold(b)
        b.allowhold = false

        update_board!(oldboard, b)
    end
end
