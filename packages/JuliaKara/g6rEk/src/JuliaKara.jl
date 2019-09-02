module JuliaKara
using Blink
include("JuliaKara_noGUI.jl"); using .JuliaKara_noGUI

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
    reloadGUI,
    @World,
    save_world,
    load_world,
    get_kara,
    store!,
    reset!,
    world_state_save

import .JuliaKara_noGUI:World,
    place_kara,
    place_tree,
    place_leaf,
    place_mushroom,
    move,
    turnLeft,
    turnRight,
    removeLeaf,
    putLeaf,
    treeLeft,
    treeRight,
    treeFront,
    mushroomFront,
    onLeaf,
    orientation_to_rad,
    Actor,
    get_kara,
    reset!

import .JuliaKara_noGUI.ActorsWorld:Location,
get_actors_at_location_on_layer,
location_move,
location_fix_ooBound,
LocationFullError,
actor_delete!

"""
    World_GUI(world::World,canvas::GtkCanvas,saved_world::World_State,drawing_delay::Float64)

Creates a new World with a GUI component. Contains the actual `world` the `canvas` used for drawing.
A state `saved_world` the world can be reverted to and a `drawing_delay`.
Is used for every GUI communication.
"""
mutable struct World_GUI
    world::World
    window::Window
    saved_world::World_State
    drawing_delay::Float64
    actor_ids::Dict{Actor,Int}
    id_counter::Int
    World_GUI(world,window,saved_world,drawing_delay) = begin
        new(world,window,saved_world,drawing_delay,Dict{Actor,Int}(),0)
    end
end

function get_next_id(w::World_GUI)
    w.id_counter += 1
    return w.id_counter
end

"""
    World(height::Int,width::Int,name::AbstractString)

Creates a new world of size `width` x `height`. `name` is used as a title for the
GTK window.
"""
function World(height::Int,width::Int,name::AbstractString)
    world = World(height,width)
    world_gui = World_GUI(
        world,
        Window(),
        world_state_save(world),
        0,
    )
    Blink.AtomShell.title(world_gui.window,name)
    loadGUI(world_gui)
    return world_gui
end

function reloadGUI(wo::World_GUI)
    wo.window = Window()
    loadGUI(wo)
    drawActors(wo)
    return wo
end

function drawActors(wo::World_GUI)
    @js_ wo.window world.imgs = []
    for ac in wo.world.actors
        if ac.actor_definition == JuliaKara_noGUI.ACTOR_DEFINITIONS[:kara]
            draw_kara(wo,ac)
        elseif ac.actor_definition == JuliaKara_noGUI.ACTOR_DEFINITIONS[:mushroom]
            draw_mushroom(wo,ac)
        elseif ac.actor_definition == JuliaKara_noGUI.ACTOR_DEFINITIONS[:tree]
            draw_tree(wo,ac)
        elseif ac.actor_definition == JuliaKara_noGUI.ACTOR_DEFINITIONS[:leaf]
            draw_leaf(wo,ac)
        else
            error("Missing actor definition, cant draw shape.")
        end
    end
end

function loadGUI(world_gui::World_GUI)
    window = world_gui.window
    wait_until_defined(window,:Blink)
    # Load Vue
    load!(window,joinpath(@__DIR__,"..","res/js/vue.js"),async=false)
    wait_until_defined(window,:Vue)
    # Load Resources
    joinpath(@__DIR__,"res/icons/bugnorth.png")
    Blink.resource(joinpath(@__DIR__,"..","res/icons/load.png"))
    Blink.resource(joinpath(@__DIR__,"..","res/icons/save.png"))
    Blink.resource(joinpath(@__DIR__,"..","res/icons/bugnorth.png"))
    Blink.resource(joinpath(@__DIR__,"..","res/icons/object_tree.png"))
    Blink.resource(joinpath(@__DIR__,"..","res/icons/object_leaf.png"))
    Blink.resource(joinpath(@__DIR__,"..","res/icons/object_mushroom.png"))
    Blink.resource(joinpath(@__DIR__,"..","res/icons/trashcanbig.png"))
    # Load body
    body!(window,read(joinpath(@__DIR__,"..","res/main.html"),String),async=false)
    wait_until_defined(window,:grid)
    blink_set_Grid!(world_gui)
    @js window grid.draw()
    @js window grid.draw()
    # Register handles
    handle(drop_actor_wrapper(world_gui),window,"drop_actor")
    handle(delete_actor_wrapper(world_gui),window,"delete_actor")
    handle(create_actor_wrapper(world_gui),window,"create_actor")
    handle(change_delay_wrapper(world_gui),window,"change_speed")
    handle(load_world_wrapper(world_gui),window,"load")
    handle(save_world_wrapper(world_gui),window,"save")
end

function change_delay_wrapper(world::World_GUI)
    return function (args)
        speed = parse(Int,args)
        world.drawing_delay = 2.0-(2.0/100.0*speed)
    end
end

function create_actor_wrapper(world::World_GUI)
    return function (args)
        typeof = args["type"]
        x = args["x"]
        y = args["y"]

        create_funs = [
            (x,y) -> place_kara(world,x,y,:NORTH)
            (x,y) -> place_tree(world,x,y)
            (x,y) -> place_mushroom(world,x,y)
            (x,y) -> place_leaf(world,x,y)
        ]
        try
            ac = create_funs[typeof](x,y)
        catch e
            if !isa(e,LocationFullError)
                throw(e)
            end
        end
    end
end

function delete_actor_wrapper(world::World_GUI)
    return function (args)
        id = parse(Int,args["id"])
        for a in world.world.actors
            if world.actor_ids[a] == id
                js_remove_actor(world,a)
                delete!(world.actor_ids,a)
                actor_delete!(world.world,a)
                return
            end
        end
        @error "Actor with $id not found!"
    end
end

function drop_actor_wrapper(world::World_GUI)
    return function (args)
        id = parse(Int,args["id"])
        x = args["x"]
        y = args["y"]
        for a in world.world.actors
            if world.actor_ids[a] == id
                try
                    JuliaKara_noGUI.actor_moveto!(
                        world.world,
                        a,
                        JuliaKara_noGUI.Location(
                            x,y
                        )
                    )
                    js_update_actor(world,a)
                catch e
                    if !isa(e,LocationFullError)
                        throw(e)
                    end
                end
                return
            end
        end
        @error "Actor with $id not found!"
    end
end

function load_world_wrapper(wo::World_GUI)
    return function(args)
       path = js(wo.window.shell, Blink.js"""
       var electron = require('electron');
       electron.dialog.showOpenDialog(
        {
            title: "Open Kara world-file",
            properties: ['openFile'],
            filters: [
                       {name: 'world-file', extensions: ['world',]},
                     ]

        })
       """)
        # path = open_dialog("Pick a World-File", b["win_main"], ("*.world",))
        if path != nothing
            wo.world = JuliaKara_noGUI.load_world(path[1])
            wo.saved_world = world_state_save(wo.world)
            drawActors(wo)
            blink_set_Grid!(wo)
        end
    end
end

function save_world_wrapper(wo::World_GUI)
    return function(args)
       path = js(wo.window.shell, Blink.js"""
       var electron = require('electron');
       electron.dialog.showSaveDialog(
        {
            title: "Save Kara world-file",
            filters: [
                       {name: 'World-File', extensions: ['world',]},
                     ]

        })
       """)
        if path != nothing
            save_world(
                wo,
                path
            )
        end
    end
end

function js_isdefined(d::Dict{String,Any})
    length(d) > 0
end

function js_isdefined(d::AbstractString)
    d != "undefined"
end

function wait_until_defined(w::Window,var::Symbol)
    for i in 1:100
        res = @js w typeof($var)
        if js_isdefined(res)
            return
        else
            sleep(0.1)
        end
    end
    @error "Error after loading $var. It is still not defined."
end

function blink_set_Grid!(w::World_GUI)
    width = w.world.size.width
    height = w.world.size.height
    r = @js_ w.window grid.rows = $height
    h = @js_ w.window grid.cols = $width
end

function to_js_direction(direction::Symbol)
    return findfirst(x->x==direction,JuliaKara_noGUI.ActorsWorld.DIRECTIONS)
end

"""
    place_kara(wo::World_GUI,x::Int,y::Int,direction::Symbol=:NORTH)

Places kara in world `wo` at location `x`, `y` in direction `direction`.
`direction` is either of :NORTH, :EAST, :SOUTH, :WEST.
Returns a reference to the created object.

This function is a wrapper around [`JuliaKara_noGUI.place_kara`](@ref) to support GUI.
"""
function place_kara(wo::World_GUI,x::Int,y::Int,direction::Symbol=JuliaKara_noGUI.ActorsWorld.DIRECTIONS[1])
    ac = place_kara(wo.world,x,y,direction)
    draw_kara(wo,ac)
    return ac
end

function draw_kara(wo::World_GUI,ac::Actor)
    newid = get_next_id(wo)
    wo.actor_ids[ac] = newid
    jsdir = to_js_direction(ac.orientation.value)
    x = ac.location.x
    y = ac.location.y
    @js_ wo.window world.place($newid,$x,$y,$jsdir,"bugnorth.png",$(ac.actor_definition.layer))
end

"""
    place_tree(wo::World_GUI,x::Int,y::Int)

Places a tree in world `wo` at location `x`, `y`.
Returns a referenc to the created object.

This function is a wrapper around [`JuliaKara_noGUI.place_tree`](@ref) to support GUI.
"""
function place_tree(wo::World_GUI,x::Int,y::Int)
    ac = place_tree(wo.world,x,y)
    draw_tree(wo,ac)
    return ac
end

function draw_tree(wo::World_GUI,ac::Actor)
    newid = get_next_id(wo)
    wo.actor_ids[ac] = newid
    x = ac.location.x
    y = ac.location.y
    @js_ wo.window world.place($newid,$x,$y,1,"object_tree.png",$(ac.actor_definition.layer))
end

"""
    place_leaf(wo::World_GUI,x::Int,y::Int)

Places a leaf in world `wo` at location `x`, `y`.
Returns a referenc to the created object.

This function is a wrapper around [`JuliaKara_noGUI.place_leaf`](@ref) to support GUI.
"""
function place_leaf(wo::World_GUI,x::Int,y::Int)
    ac = place_leaf(wo.world,x,y)
    draw_leaf(wo,ac)
    return ac
end

function draw_leaf(wo::World_GUI,ac::Actor)
    newid = get_next_id(wo)
    wo.actor_ids[ac] = newid
    x = ac.location.x
    y = ac.location.y
    @js_ wo.window world.place($newid,$x,$y,1,"object_leaf.png",$(ac.actor_definition.layer))
end

"""
    place_mushroom(wo::World_GUI,x::Int,y::Int)

Places a mushroom in world `wo` at location `x`, `y`.
Returns a referenc to the created object.

This function is a wrapper around [`JuliaKara_noGUI.place_mushroom`](@ref) to support GUI.
"""
function place_mushroom(wo::World_GUI,x::Int,y::Int)
    ac = place_mushroom(wo.world,x,y)
    draw_mushroom(wo,ac)
    return ac
end

function draw_mushroom(wo::World_GUI,ac::Actor)
    newid = get_next_id(wo)
    wo.actor_ids[ac] = newid
    x = ac.location.x
    y = ac.location.y
    @js_ wo.window world.place($newid,$x,$y,1,"object_mushroom.png",$(ac.actor_definition.layer))
end

function js_update_actor(wo::World_GUI,ac::Actor)
    @js_ wo.window world.update_actor($(wo.actor_ids[ac]),$(ac.location.x),$(ac.location.y),$(to_js_direction(ac.orientation.value)))
end

function js_remove_actor(wo::World_GUI,ac::Actor)
    @js_ wo.window world.remove_actor($(wo.actor_ids[ac]))
end

function delay(wo::World_GUI)
    if wo.drawing_delay > 0
        sleep(wo.drawing_delay)
    end
end

"""
    move(wo::World_GUI,ac::Actor)

Moves the actor `ac` a step forward in the world `wo`.

This function is a wrapper around [`JuliaKara_noGUI.move`](@ref) to support GUI.
"""
function move(wo::World_GUI,ac::Actor)
    # In case the actor in front of kara is moveable,
    # additionally two fields need to be repainted.
    front_lo = location_move(ac.location,ac.orientation)
    actors_in_front = get_actors_at_location_on_layer(
        wo.world,
        front_lo,
        ac.actor_definition.layer
    )
    move(wo.world,ac)
    js_update_actor(wo,ac)
    js_update_actor.(Ref(wo),actors_in_front)
    delay(wo)
    return nothing
end

"""
    turnLeft(wo::World_GUI,ac::Actor)

Turns the actor `ac` counter clockwise.

This function is a wrapper around [`JuliaKara_noGUI.turnLeft`](@ref) to support GUI.
"""
function turnLeft(wo::World_GUI,ac::Actor)
    turnLeft(wo.world,ac)
    js_update_actor(wo,ac)
    delay(wo)
end

"""
    turnRight(wo::World_GUI,ac::Actor)

Turns the actor `ac` clockwise.

This function is a wrapper around [`JuliaKara_noGUI.turnRight`](@ref) to support GUI.
"""
function turnRight(wo::World_GUI,ac::Actor)
    turnRight(wo.world,ac)
    js_update_actor(wo,ac)
    delay(wo)
end

"""
    removeLeaf(wo::World_GUI,ac::Actor)

Removes an actor of type leaf from the location `ac` is at.

This function is a wrapper around [`JuliaKara_noGUI.removeLeaf`](@ref) to support GUI.
"""
function removeLeaf(wo::World_GUI,ac::Actor)
    layer = JuliaKara_noGUI.ACTOR_DEFINITIONS[:leaf].layer
    leaf = get_actors_at_location_on_layer(wo.world,ac.location,layer)
    if length(leaf) > 0
        js_remove_actor(wo,leaf[1])
        delete!(wo.actor_ids,leaf[1])
    end
    removeLeaf(wo.world,ac)
    delay(wo)
end

"""
    putLeaf(wo::World_GUI,ac::Actor)

Places an actor of type leaf the location `ac` is at.

This function is a wrapper around [`JuliaKara_noGUI.putLeaf`](@ref) to support GUI.
"""
function putLeaf(wo::World_GUI,ac::Actor)
    place_leaf(wo,ac.location.x,ac.location.y)
    delay(wo)
end

"""
    treeLeft(wo::World_GUI,ac::Actor)

Checks if there is an actor of type tree left of actor `ac`.

This function is a wrapper around [`JuliaKara_noGUI.treeLeft`](@ref) to support GUI.
"""
treeLeft(wo::World_GUI,ac::Actor) = treeLeft(wo.world,ac)

"""
    treeRight(wo::World_GUI,ac::Actor)

Checks if there is an actor of type tree right of actor `ac`.

This function is a wrapper around [`JuliaKara_noGUI.treeRight`](@ref) to support GUI.
"""
treeRight(wo::World_GUI,ac::Actor) = treeRight(wo.world,ac)

"""
    treeFront(wo::World_GUI,ac::Actor)

Checks if there is an actor of type tree in front of actor `ac`.

This function is a wrapper around [`JuliaKara_noGUI.treeFront`](@ref) to support GUI.
"""
treeFront(wo::World_GUI,ac::Actor) = treeFront(wo.world,ac)

"""
    mushroomFront(wo::World_GUI,ac::Actor)

Checks if there is an actor of type mushroom in front of actor `ac`.

This function is a wrapper around [`JuliaKara_noGUI.mushroomFront`](@ref) to support GUI.
"""
mushroomFront(wo::World_GUI,ac::Actor) = mushroomFront(wo.world,ac)

"""
    onLeaf(wo::World_GUI,ac::Actor)

Checks if there is an actor of type leaf below of actor `ac`.

This function is a wrapper around [`JuliaKara_noGUI.onLeaf`](@ref) to support GUI.
"""
onLeaf(wo::World_GUI,ac::Actor) = onLeaf(wo.world,ac)

"""
    @World [name] defintion

`definition` is either a `String` describing the path to a world-file which
should be loaded or a `Tuple{Int,Int}` describing the height and the width
of the world

In case a `name` is provided (Must be a name that can be used as a variable name)
a variable in global scope named `name` and a macro named `@name` are created
which allow access to the world (See Examples).

In case no `name` is provided the world is stored in global scope in a variable
named `world` and kara is placed at location 1,1 and refereced with
a global variable named `kara`. Furthermore all function used for interaction
with kara (`move()`, `turnLeft()`, ...) are extended with methods to allow
calls like `move(kara)`.

# Examples
```julia-repl
julia> @World (10,10)
julia> move(kara) # moves kara in world
julia> @world testw (10,10)
julia> lara = @testw place_kara()
julia> @testw move(lara) # moves lara in testw
```
"""
macro World(definition)
    esc(quote
            if typeof($definition) == String
                world = load_world(
                    $definition,
                    "JuliaKara"
                )
            else
                world = World($definition...,"JuliaKara")
                place_kara(world,1,1)
            end
            kara = get_kara(world)
            import JuliaKara.JuliaKara_noGUI:move,
                turnLeft,
                turnRight,
                putLeaf,
               removeLeaf,
                onLeaf,
                treeFront,
                treeLeft,
                treeRight,
                mushroomFront
            function move(ac::JuliaKara.JuliaKara_noGUI.Actor)
                move(world,ac)
            end
            function turnLeft(ac::JuliaKara.JuliaKara_noGUI.Actor)
                turnLeft(world,ac)
            end
            function turnRight(ac::JuliaKara.JuliaKara_noGUI.Actor)
                turnRight(world,ac)
            end
            function putLeaf(ac::JuliaKara.JuliaKara_noGUI.Actor)
                putLeaf(world,ac)
            end
            function removeLeaf(ac::JuliaKara.JuliaKara_noGUI.Actor)
                removeLeaf(world,ac)
            end
            function onLeaf(ac::JuliaKara.JuliaKara_noGUI.Actor)
                onLeaf(world,ac)
            end
            function treeFront(ac::JuliaKara.JuliaKara_noGUI.Actor)
                treeFront(world,ac)
            end
            function treeLeft(ac::JuliaKara.JuliaKara_noGUI.Actor)
                treeLeft(world,ac)
            end
            function treeRight(ac::JuliaKara.JuliaKara_noGUI.Actor)
                treeRight(world,ac)
            end
            function mushroomFront(ac::JuliaKara.JuliaKara_noGUI.Actor)
                mushroomFront(world,ac)
            end
            nothing
        end
        )
end

macro World(name,definition)
    str_name = string(name)
    esc(quote
        if typeof($definition) == String
            $name = load_world(
                $definition,
                $str_name
            )
        else
            $name = World($definition...,$str_name)
        end
        macro $name(command)
            if command.head == :block
                for ca in command.args
                    if ca.head == :call
                        insert!(ca.args,2,$name)
                    end
                end
            elseif command.head == :call
                insert!(command.args,2,$name)
        end
        return command

        end
        nothing
        end)
end

"""
    load_world(path::AbstractString,name::AbstractString)

Loads a world-file from `path` and names the new window `name`.
Creates a new GTK window.
"""
function load_world(path::AbstractString,name::AbstractString)
    loaded_wo = JuliaKara_noGUI.load_world(path)
    wo = World(loaded_wo.size.width,loaded_wo.size.height,name)
    wo.world = loaded_wo
    wo.saved_world = world_state_save(wo.world)
    blink_set_Grid!(wo)
    drawActors(wo)
    return wo
end

"""
    save_world(wo::World_GUI,path::AbstractString)

Saves a world `wo` into a world-file at `path`.
"""
function save_world(wo::World_GUI,path::AbstractString)
    JuliaKara_noGUI.save_world(wo.world,path)
end

get_kara(wo::World_GUI) = get_kara(wo.world)

"""
    store!(wo::World_GUI)

Stores a state of a world `wo` in `wo.saved_world`.
Can be restored by using `reset!(wo::World)`.

# Exaples
```julia-repl
julia> store!(wo)
julia> # do something in wo
julia> reset!(wo)
```
"""
function store!(wo::World_GUI)
    wo.saved_world = world_state_save(wo.world)
end

function reset!(wo::World_GUI,wst::World_State)
    reset!(wo.world,wst)
    drawActors(wo)
    nothing
end

"""
    reset!(wo::World_GUI)

Resets a world `wo` back to a given state `wo.saved_world`.
Can be stored using `store!(wo)`.
Loading a world from a file stores to state at time of loading.

# Examples
```julia-repl
julia> store!(wo)
julia> # Do something in wo
julia> reset!(wo)
```
"""
function reset!(wo::World_GUI)
    reset!(wo,wo.saved_world)
end

end
