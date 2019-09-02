# JuliaKara
<div align="center">
<img src="https://i.imgur.com/g3noPR3.gif" width=500 />
</div>

[![Build Status](https://travis-ci.org/sebastianpech/JuliaKara.jl.svg?branch=master)](https://travis-ci.org/sebastianpech/JuliaKara.jl)
[![codecov.io](http://codecov.io/github/sebastianpech/JuliaKara.jl/coverage.svg?branch=master)](http://codecov.io/github/sebastianpech/JuliaKara.jl?branch=master)
[![](https://img.shields.io/badge/docs-stable-blue.svg)](https://sebastianpech.github.io/JuliaKara.jl/stable)
[![](https://img.shields.io/badge/docs-latest-blue.svg)](https://sebastianpech.github.io/JuliaKara.jl/latest)

A package that is a port of SwissEducs [Kara](http://www.swisseduc.ch/informatik/karatojava/) (Page in German).
Kara is a concept for an easy access into the world of programming.
Kara is a tiny ladybug living in a forest with mushrooms, trees and leafs.
Kara can move a single mushroom, place and remove leafs, cannot move trees and is entirely controlled using julia code.
In comparison to the original Kara the interaction manly focuses on using the REPL.

## Installation
Install within Julia in the Pkg REPL-mode using

```jl
add JuliaKara
```

or in Julia 0.6 in REPL-mode using

```jl
Pkg.add("JuliaKara")
```

## Introduction

Start using JuliaKara by opening Julia and entering `using JuliaKara` into the REPL.
Next create a new world of size 10x10 with function bindings in global scope by entering `@World (10,10)`.

You can now use
- `move(kara)` to make a step into the direction Kara is facing,
- `turnLeft(kara)` to turn Kara left,
- `turnRight(kara)` to turn Kara right,
- `putLeaf(kara)` to place a leaf beneath Kara and
- `removeLeaf(kara)` to remove a leaf from beneath Kara

and

- `treeFront(kara)` to check if Kara stands in front of a tree,
- `treeLeft(kara)` to check if there is a tree left of Kara,
- `treeRight(kara)` to check if there is a tree right of Kara,
- `onLeaf(kara)` to check if there is a leaf beneath Kara and
- `mushroomFront(kara)` to check if Kara stands in front of a mushroom.

### Alternative methods of creating/loading a world

JuliaKara is aware of the xml syntax the original Kara uses for storing worlds in files.
It's possible to load a world through the GUI or with the command `@World [path]`.
In contrast to the GUI version `@World [path]` opens a new window and registers `world` and `kara` in global scope as references.

```jl
@World "file1.world"
move(kara) # moves Kara in world from file1.world

@World "file2.world"
# kara and world referencing elements from file1.world
# are now overwritten with references to elements from file2.world
move(kara) # moves Kara in world from file2.world

# Create additional references to world and kara
world_save = world
kara_save = kara

@World "file3.world"
# kara and world referencing elements from file2.world
# are now overwritten with references to elements from file3.world
move(kara) # moves Kara in world from file3.world

# Access stored references
move(world_save,kara_save) # moves Kara in world from file2.world
```

In case one loads a world through the GUI and wants the above behaviour, the reference to Kara must be restored by:

```jl
kara = get_kara(world)
```

JuliaKara supports multiple worlds and multiple Karas. In case you want to reproduce the example run it from within the test directory of JuliaKara e.g `~/.Julia/v0.6/JuliaKara/test`.

```jl
# Load the world contained in example.world.
# This also creates a macro @w1 in global scope to interact with 
# the world
@World w1 "example.world"

# Create an empty world w2
@World w2 (10,2)

# Place kara in the empty world.
# place_kara() returns a reference to the placed kara.
# @w2 place_kara(1,1) is just syntactic sugar for place_kara(w2,1,1)
kara = @w2 place_kara(1,1)

# Kara is already placed in world w1, therefore we fetch it with get_kara()
# Since we can't create two kara references we use lara instead.
lara = @w1 get_kara()

# Move lara a step in world w1
@w1 move(lara)
# Alternatively:
move(w1,lara)

# Move kara a step in world w2
@w2 move(kara)

# It's even possible to allow kara from world w2 to 
# place something in world w1
@w1 putLeaf(kara)

```

### Other useful methods

- `reset!(world)`: Resets `world` to the state after loading or the last call to `store!(world)`.
- `store!(world)`: Stores the current state of `world`.
- `place_kara(world,X,Y,orientation)`: Places Kara in `world` at `X`, `Y` oriented `orientation`. Valid orientations are `:NORTH`, `:EAST`, `:SOUTH` and `:WEST`. `orientation` is optional and defaults to `:NORTH`.
- `place_mushroom(world,X,Y)`: Places a mushroom in `world` at `X`, `Y`.
- `place_tree(world,X,Y)`: Places a tree in `world` at `X`, `Y`.
- `place_leaf(world,X,Y)`: Places a leaf in `world` at `X`, `Y`.

The above used macro for interaction e.g. `@w1` basically translate `@w1 f(args...)` to `f(w1,args...)`.
Thus as all the above methods have `world` as their first argument they can also be called using the world macro.
This also works for custom methods:

```jl
function turnAround(wo,ka)
	turnLeft(wo,ka)
	turnLeft(wo,ka)
end

@w1 turnAround(lara)
```

## Examples

The [examples page](https://sebastianpech.github.io/JuliaKara-Examples/) for
JuliaKara contains further material showing the usage of JuliaKara.
