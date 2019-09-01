"""
    NodePosition

Represents the position and velocity of a node during force directed layouts. The
fields are `x` and `y` for position, and `vx` and `vy` for their relative
velocity.
"""
mutable struct NodePosition
    x::Float64
    y::Float64
    vx::Float64
    vy::Float64
    r::Number
end

NodePosition() = NodePosition(rand(), rand(), 0.0, 0.0, 0.0)
NodePosition(x::Float64, y::Float64) = NodePosition(x, y, 0.0, 0.0, 0.0)
NodePosition(x::Float64, y::Float64, vx::Float64, vy::Float64) = NodePosition(x, y, vx, vy, 0.0)

function NodePosition(r::T) where {T <: Number}
    return NodePosition(0.0, 0.0, 0.0, 0.0, r)
end

function NodePosition(x::Float64, y::Float64, r::T) where {T <: Number}
    return NodePosition(x, y, 0.0, 0.0, r)
end

"""
    BipartiteInitialLayout

This type is used to generate an initial bipartite layout, where the nodes are
placed on two levels, but their horizontal position is random.
"""
struct BipartiteInitialLayout end

"""
    FoodwebInitialLayout

This type is used to generate an initial layout, where the nodes are
placed on their trophic levels, but their horizontal position is random.
"""
struct FoodwebInitialLayout end


"""
    RandomInitialLayout

This type is used to generate an initial layout, where the nodes are
placed at random.
"""
struct RandomInitialLayout end

"""
    CircularInitialLayout

This type is used to generate an initial layout, where the nodes are
placed at random along a circle.
"""
struct CircularInitialLayout end
