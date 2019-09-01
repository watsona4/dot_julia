# EntityComponentSystem.jl 🍱

An entity component system written for Julia for video games and other simulations.

```julia
add "EntityComponentSystem"
```
Documentation is [here](https://richardanaya.github.io/EntityComponentSystem.jl/build/index.html)

## Simple Example

```julia
using EntityComponentSystem

mutable struct Position <: ECSComponent
  x::Float32
  y::Float32
end

mutable struct Velocity <: ECSComponent
  x::Float32
  y::Float32
end

# Create a world for entities
world = World()

# Register memory storage for components
register!(world,Position)
register!(world,Velocity)

# Create entities
player = createentity!(world)
addcomponent!(world,player,Position(0,0))
addcomponent!(world,player,Velocity(1,2))

FPS = 60.0

function runphysics!()
  while true
    global world
    # Run systems on entities with specific sets of components
    runsystem!(world,[Position,Velocity]) do entity,components
        # Components are given in order they are requested
        pos,vel = components
        # Modify components
        pos.x += vel.x
        pos.y += vel.y
    end
    sleep(1.0/FPS)
  end
end

@async runphysics!()
```
