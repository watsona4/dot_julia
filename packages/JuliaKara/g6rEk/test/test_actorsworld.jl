module actor_world_test
using Test
include("../src/ActorsWorld.jl"); using .ActorsWorld


@testset "Actors-World" begin
    @testset "Basic" begin
        or = Orientation(ActorsWorld.DIRECTIONS[1])
        @test orientation_rotate(or,Val{true}).value == ActorsWorld.DIRECTIONS[2]
        @test orientation_rotate(or,Val{false}).value == ActorsWorld.DIRECTIONS[4]
        @test orientation_rotate(Orientation(ActorsWorld.DIRECTIONS[2]),Val{true}).value == ActorsWorld.DIRECTIONS[3]
        @test orientation_rotate(Orientation(ActorsWorld.DIRECTIONS[3]),Val{true}).value == ActorsWorld.DIRECTIONS[4]
        @test orientation_rotate(Orientation(ActorsWorld.DIRECTIONS[4]),Val{true}).value == ActorsWorld.DIRECTIONS[1]
        @test_throws InvalidDirectionError Orientation(:foo)
        lo = Location(1,2)
        wo = World(10,13)
        @test location_move(lo,Orientation(ActorsWorld.DIRECTIONS[2])).x == 2
        @test location_fix_ooBound(wo,Location(0,15)) == Location(10,2)
    end
    @testset "World generation" begin
        wo = World(10,12)
        @test wo.size.height == 12
        @test wo.size.width == 10
    end
    @testset "Actors" begin
        kara = Actor_Definition(
            moveable=true,
            turnable=true
        )
        leaf = Actor_Definition(
            layer=0
        )
        wo = World(10,10)
        ac1 = actor_create!(wo,kara,Location(1,3),Orientation(ActorsWorld.DIRECTIONS[1]))
        ac1_c = copy(ac1)
        @test ac1_c.actor_definition == ac1.actor_definition
        @test ac1_c.location == ac1.location
        @test ac1_c.orientation == ac1.orientation
        @test ac1 == wo.actors[1]
        actor_delete!(wo,ac1)
        @test length(wo.actors) == 0
        ac2 = actor_create!(wo,kara,Location(1,3),Orientation(ActorsWorld.DIRECTIONS[1]))
        ac3 = actor_create!(wo,leaf,Location(1,3),Orientation(ActorsWorld.DIRECTIONS[1]))
        @test length(get_actors_at_location(wo,Location(1,3))) == 2
        @test length(get_actors_at_location(wo,Location(2,3))) == 0
        @test_throws LocationFullError actor_create!(wo,kara,Location(1,3),
                                                     Orientation(ActorsWorld.DIRECTIONS[1]))
        k2 = actor_create!(wo,kara,Location(5,5),Orientation(ActorsWorld.DIRECTIONS[1]))
        @test_throws LocationFullError actor_create!(wo,kara,Location(5,5),Orientation(ActorsWorld.DIRECTIONS[1]))
        actor_delete!(wo,k2)
        @test_throws ActorNotFound actor_delete!(wo,k2)

        actor_moveto!(wo,ac2,Location(10,10))
        @test ac2.location == Location(10,10)
        actor_create!(wo,kara,Location(5,5),Orientation(ActorsWorld.DIRECTIONS[1]))
        @test_throws LocationFullError actor_moveto!(wo,ac2,Location(5,5))
        wo_c = copy(wo)
        @test length(wo_c.actors) == length(wo.actors)
        @test wo_c.size == wo.size
    end
    @testset "World Boundaries" begin
        ka = Actor_Definition(
            moveable=true,
            turnable=true
        )
        wo = World(2,5)
        ac = actor_create!(
            wo,ka,Location(1,1),Orientation(ActorsWorld.DIRECTIONS[1])
        )
        @test_throws LocationOutsideError actor_create!(
            wo,ka,Location(1,10),Orientation(ActorsWorld.DIRECTIONS[1])
        )
        actor_move!(wo,ac,ActorsWorld.DIRECTIONS[1]) # 1,2
        actor_move!(wo,ac,ActorsWorld.DIRECTIONS[1]) # 1,3
        actor_move!(wo,ac,ActorsWorld.DIRECTIONS[1]) # 1,4
        actor_move!(wo,ac,ActorsWorld.DIRECTIONS[1]) # 1,5
        @test ac.location == Location(1,5)
        actor_move!(wo,ac,ActorsWorld.DIRECTIONS[1]) # 1,1
        @test ac.location == Location(1,1)
        actor_move!(wo,ac,ActorsWorld.DIRECTIONS[1]) # 1,2
        @test ac.location == Location(1,2)
        actor_rotate!(ac,true)
        @test ac.orientation == Orientation(ActorsWorld.DIRECTIONS[2])
        actor_move!(wo,ac,ActorsWorld.DIRECTIONS[2]) # 2,2
        actor_move!(wo,ac,ActorsWorld.DIRECTIONS[2]) # 1,2
        @test ac.location == Location(1,2)
    end
    @testset "Moving other Actors" begin
        kara_2 = Actor_Definition(
            moveable=true,
            turnable=true
        )
        mushroom = Actor_Definition(
            moveable=true,
        )
        tree = Actor_Definition(
            moveable=false
        )
        wo = World(2,5)
        ac_kara_2 = actor_create!(
            wo,kara_2,Location(1,1),Orientation(ActorsWorld.DIRECTIONS[1])
        )
        ac_mushroom = actor_create!(
            wo,mushroom,Location(1,2),Orientation(ActorsWorld.DIRECTIONS[1])
        )
        actor_move!(wo,ac_kara_2,ActorsWorld.DIRECTIONS[1])
        @test ac_mushroom.location.y == 3
        actor_move!(wo,ac_kara_2,ActorsWorld.DIRECTIONS[3])
        ac_mushroom2 = actor_create!(
            wo,mushroom,Location(1,2),Orientation(ActorsWorld.DIRECTIONS[1])
        )
        actor_create!(
            wo,tree,Location(2,1),Orientation(ActorsWorld.DIRECTIONS[1])
        )
        @test_throws ActorInvalidMultipleMovementError actor_move!(wo,ac_kara_2,ActorsWorld.DIRECTIONS[1])
        @test_throws ActorInvalidMovementError actor_move!(wo,ac_kara_2,ActorsWorld.DIRECTIONS[2])
    end
    @testset "Putting and Picking" begin
        wo = World(1,10)
        leaf = Actor_Definition(
            layer=0,
            grabable=true
        )
        leaf_2 = Actor_Definition(
            layer=-1,
            grabable=true
        )
        kara_p = Actor_Definition()
        kara_ac = actor_create!(wo,kara_p,Location(1,1),Orientation(ActorsWorld.DIRECTIONS[1]))
        actor_putdown!(wo,kara_ac,leaf)
        @test wo.actors[2].actor_definition == leaf
        actor_pickup!(wo,kara_ac)
        @test length(wo.actors) == 1
        @test_throws ActorGrabNotFoundError actor_pickup!(wo,kara_ac)
        @test_throws ActorInvalidGrabError actor_putdown!(wo,kara_ac,kara_p)
        @test_throws ActorNotPlaceableError actor_putdown!(wo,kara_ac,leaf_2)
    end
    @testset "Sensors" begin
        wo = World(10,10)
        acd = Actor_Definition()
        acdp = Actor_Definition(layer=0)
        ac = actor_create!(wo,acd,Location(5,5),Orientation(:NORTH))
        actor_create!(wo,acd,Location(6,5),Orientation(:NORTH))
        actor_create!(wo,acd,Location(5,6),Orientation(:NORTH))
        actor_create!(wo,acdp,Location(5,5),Orientation(:NORTH))
        @test is_actor_definition_left(wo,ac,acd) == false
        @test is_actor_definition_right(wo,ac,acd) == true
        @test is_actor_definition_front(wo,ac,acd) == true
        @test is_actor_definition_right(wo,ac,Actor_Definition(moveable=true)) == false
        @test is_actor_definition_here(wo,ac,acdp) == true
    end
end
end
