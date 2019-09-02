using JuliaKara
@World "./intro.world"

world.drawing_delay = 0.03

function line(kara,length::Int)
    for i in 1:length
        putLeaf(kara)
        i == length || move(kara)
    end
end

function turnAround(kara)
    turnLeft(kara)
    turnLeft(kara)
end

function move(kara,steps::Int)
    for i in 1:steps
        move(kara)
    end
end

function diagonal(kara,length::Int,direction::Symbol=:up)
    if direction == :up
        rot = [
            turnLeft,
            turnRight
        ]
    elseif direction == :down
        rot = [
            turnRight,
            turnLeft
        ]
    end
    for i in 1:length
        putLeaf(kara)
        i==length || begin
            rot[1](kara)
            move(kara)
            rot[2](kara)
            move(kara)
        end
    end
end

function K(kara)
    line(kara,5)
    turnAround(kara)
    move(kara,2)
    turnLeft(kara)
    move(kara)
    diagonal(kara,3)
    turnRight(kara)
    move(kara,3)
    turnRight(kara)
    move(kara)
    turnAround(kara)
    diagonal(kara,2,:down)
end

function around_A(kara)
    turnLeft(kara)
    move(kara,4)
    turnRight(kara)
    move(kara,4)
    turnRight(kara)
    move(kara)
    turnLeft(kara)
    move(kara,2)
    turnLeft(kara)
    move(kara)
    turnLeft(kara)
    move(kara,3)
    turnAround(kara)
    move(kara,2)    
end

function R(kara)
    turnRight(kara)
    line(kara,5)
    turnLeft(kara)
    move(kara,3)
    turnAround(kara)
    diagonal(kara,3,:down)
    turnAround(kara)
    move(kara)
    putLeaf(kara)
    move(kara)
    turnLeft(kara)
    move(kara)
    putLeaf(kara)
    move(kara)
    turnLeft(kara)
    move(kara)
    putLeaf(kara)
    move(kara)
    putLeaf(kara)
end

function A(kara)
    turnRight(kara)
    move(kara)
    line(kara,4)
    turnLeft(kara)
    move(kara)
    turnLeft(kara)
    move(kara,2)
    putLeaf(kara)
    move(kara,2)
    putLeaf(kara)
    turnRight(kara)
    move(kara)
    turnRight(kara)
    move(kara)
    line(kara,4)
end
store!(world)
reset!(world)

K(kara)
move(kara)
around_A(kara)
R(kara)
turnAround(kara)
move(kara,4)
A(kara)
turnLeft(kara)
move(kara)
