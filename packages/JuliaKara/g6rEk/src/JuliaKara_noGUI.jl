module JuliaKara_noGUI

include("ActorsWorld.jl"); using .ActorsWorld

export
    World,
    place_kara,
    place_tree,
    place_leaf,
    place_mushroom,
    move,
    turnLeft,
    turnRight,
    putLeaf,
    removeLeaf,
    treeLeft,
    treeFront,
    treeRight,
    mushroomFront,
    onLeaf,
    load_world,
    save_world,
    get_kara,
    reset!,
    World_State,
    world_state_save

const ACTOR_DEFINITIONS = Dict(
    :kara => Actor_Definition(
        moveable=true,
        turnable=true
    ),
    :tree => Actor_Definition(),
    :mushroom => Actor_Definition(
        moveable=true
    ),
    :leaf => Actor_Definition(
        grabable=true,
        layer=0
    )
)

"""
    place_kara(wo::World,x::Int,y::Int,direction::Symbol=:NORTH)

Places kara in world `wo` at location `x`, `y` in direction `direction`.
`direction` is either of :NORTH, :EAST, :SOUTH, :WEST.
Returns a referenc to the created object.
"""
function place_kara(wo::World,x::Int,y::Int,direction::Symbol=ActorsWorld.DIRECTIONS[1])
    actor_create!(
        wo,
        ACTOR_DEFINITIONS[:kara],
        Location(x,y),
        Orientation(direction)
    )
end

"""
    place_tree(wo::World,x::Int,y::Int)

Places a tree in world `wo` at location `x`, `y`.
Returns a referenc to the created object.
"""
function place_tree(wo::World,x::Int,y::Int)
    actor_create!(
        wo,
        ACTOR_DEFINITIONS[:tree],
        Location(x,y),
        Orientation(ActorsWorld.DIRECTIONS[1])
    )
end

"""
    place_leaf(wo::World,x::Int,y::Int)

Places a leaf in world `wo` at location `x`, `y`.
Returns a referenc to the created object.
"""
function place_leaf(wo::World,x::Int,y::Int)
    actor_create!(
        wo,
        ACTOR_DEFINITIONS[:leaf],
        Location(x,y),
        Orientation(ActorsWorld.DIRECTIONS[1])
    )
end

"""
    place_mushroom(wo::World,x::Int,y::Int)

Places a mushroom in world `wo` at location `x`, `y`.
Returns a referenc to the created object.
"""
function place_mushroom(wo::World,x::Int,y::Int)
    actor_create!(
        wo,
        ACTOR_DEFINITIONS[:mushroom],
        Location(x,y),
        Orientation(ActorsWorld.DIRECTIONS[1])
    )
end

"""
    get_kara(wo::World)

Returns all actors of type kara in the world `wo`.
In case there is only one kara no vector is returned.
"""
function get_kara(wo::World)
    k_found = Actor[]
    for ac in wo.actors
        if ac.actor_definition == ACTOR_DEFINITIONS[:kara]
            push!(k_found,ac)
        end
    end
    # Return kara explicitly if only one was found
    # This is not a good style but in terms of usability
    # its better.
    return length(k_found) == 1 ? k_found[1] : k_found
end

"""
    move(wo::World,ac::Actor)

Moves the actor `ac` a step forward in the world `wo`.
"""
function move(wo::World,ac::Actor)
    actor_move!(wo,ac,ac.orientation.value)
end

"""
    turnLeft(wo::World,ac::Actor)

Turns the actor `ac` counter clockwise.
"""
function turnLeft(wo::World,ac::Actor)
    actor_rotate!(ac,false)
end

"""
    turnRight(wo::World,ac::Actor)

Turns the actor `ac` clockwise.
"""
function turnRight(wo::World,ac::Actor)
    actor_rotate!(ac,true)
end

"""
    removeLeaf(wo::World,ac::Actor)

Removes an actor of type leaf from the location `ac` is at.
"""
function removeLeaf(wo::World,ac::Actor)
    actor_pickup!(wo,ac)
end

"""
    putLeaf(wo::World,ac::Actor)

Places an actor of type leaf the location `ac` is at.
"""
function putLeaf(wo::World,ac::Actor)
    actor_putdown!(wo,ac,ACTOR_DEFINITIONS[:leaf])
end

"""
    treeLeft(wo::World,ac::Actor)

Checks if there is an actor of type tree left of actor `ac`.
"""
function treeLeft(wo::World,ac::Actor)
    is_actor_definition_left(wo,ac,ACTOR_DEFINITIONS[:tree])
end

"""
    treeRight(wo::World,ac::Actor)

Checks if there is an actor of type tree right of actor `ac`.
"""
function treeRight(wo::World,ac::Actor)
    is_actor_definition_right(wo,ac,ACTOR_DEFINITIONS[:tree])
end

"""
    treeFront(wo::World,ac::Actor)

Checks if there is an actor of type tree in front of actor `ac`.
"""
function treeFront(wo::World,ac::Actor)
    is_actor_definition_front(wo,ac,ACTOR_DEFINITIONS[:tree])
end

"""
    mushroomFront(wo::World,ac::Actor)

Checks if there is an actor of type mushroom in front of actor `ac`.
"""
function mushroomFront(wo::World,ac::Actor)
    is_actor_definition_front(wo,ac,ACTOR_DEFINITIONS[:mushroom])
end

"""
    onLeaf(wo::World,ac::Actor)

Checks if there is an actor of type leaf below of actor `ac`.
"""
function onLeaf(wo::World,ac::Actor)
    is_actor_definition_here(wo,ac,ACTOR_DEFINITIONS[:leaf])
end

include("JuliaKara_interface_xml.jl")
save_world = xml_save_world
load_world = xml_load_world

end
