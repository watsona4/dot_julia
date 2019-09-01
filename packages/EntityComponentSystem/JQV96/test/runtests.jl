using EntityComponentSystem
using Test

@testset "Basic tests" begin
    mutable struct Position <: ECSComponent
        x::Float32
        y::Float32
    end

    mutable struct Velocity <: ECSComponent
        x::Float32
        y::Float32
    end
    
    world = World()
    @test world != nothing
    register!(world,Position)
    register!(world,Velocity)
    @test world.components[Position] != nothing
    @test length(world.components[Position]) > 0
    @test world.components[Velocity] != nothing
    @test length(world.components[Velocity]) > 0
    player = createentity!(world)
    @test player != nothing
    @test world.max_entity == 1
    @test world.entity_keys[1].generation == 1
    e = getentity(world,player)
    @test e == 1
    destroyentity!(world,player)
    e = getentity(world,player)
    @test e == nothing
    player = createentity!(world)
    @test player != nothing
    @test world.max_entity == 1
    @test world.entity_keys[1].generation == 3
    player = createentity!(world)
    @test player != nothing
    @test world.max_entity == 2
    @test world.entity_keys[2].generation == 1

    addcomponent!(world,player,Position(4.0,4.0))
    @test world.components[Position][2] != nothing
    @test world.components[Position][2].x == 4.0
    removecomponent!(world,player,Position)
    @test world.components[Position][2] == nothing
    addcomponent!(world,player,Position(1.0,1.0))
    @test world.components[Position][2] != nothing
    @test world.components[Position][2].x == 1.0
    @test world.components[Position][2].y == 1.0
    addcomponent!(world,player,Velocity(1,2))
    runsystem!(world,[Position,Velocity]) do entity,components
        # Components are given in order they are requested
        pos,vel = components
        # Modify components
        pos.x += vel.x
        pos.y += vel.y
    end
    @test world.components[Position][2].x == 2.0
    @test world.components[Position][2].y == 3.0
end
