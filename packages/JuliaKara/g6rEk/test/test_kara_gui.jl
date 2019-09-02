module kara_gui
using Test
using JuliaKara

path = joinpath(@__DIR__,"..","test","example.world")

cleanup = !JuliaKara.Blink.AtomShell.isinstalled()
cleanup && JuliaKara.Blink.AtomShell.install()

@World wtest (10,10)

@testset "JuliaKara Example 01" begin
    
    kara = place_kara(wtest,4,4)

    function nextTest(world,kara)
        turnRight(world,kara)
        move(world,kara)
        turnLeft(world,kara)
    end

    @wtest place_tree(4,5)
    @wtest place_tree(5,6)
    @wtest place_mushroom(5,5)
    @wtest place_mushroom(6,5)
    @wtest place_mushroom(6,6)
    @wtest place_mushroom(7,5)
    @wtest place_leaf(8,5)

    @test_throws JuliaKara.JuliaKara_noGUI.ActorInvalidMovementError move(wtest,kara)
    nextTest(wtest,kara)
    @test_throws JuliaKara.JuliaKara_noGUI.ActorInvalidMovementError move(wtest,kara)
    nextTest(wtest,kara)
    @test_throws JuliaKara.JuliaKara_noGUI.ActorInvalidMultipleMovementError move(wtest,kara)
    nextTest(wtest,kara)
    move(wtest,kara)
    @test (mushroomFront(wtest,kara)) == true
    turnLeft(wtest,kara)
    turnLeft(wtest,kara)
    move(wtest,kara)
    turnLeft(wtest,kara)
    turnLeft(wtest,kara)
    @test (mushroomFront(wtest,kara)) == false
    nextTest(wtest,kara)
    move(wtest,kara)
    @test (onLeaf(wtest,kara)) == true
    removeLeaf(wtest,kara)
    @test (onLeaf(wtest,kara)) == false
    @test_throws JuliaKara.JuliaKara_noGUI.ActorGrabNotFoundError removeLeaf(wtest,kara)
    putLeaf(wtest,kara)
    @test (onLeaf(wtest,kara)) == true
    @test (treeLeft(wtest,kara)) == false
    @test (treeRight(wtest,kara)) == false
    @test (treeFront(wtest,kara)) == false
    place_tree(wtest,7,5)
    place_tree(wtest,9,5)
    place_tree(wtest,8,6)
    @test (treeLeft(wtest,kara)) == true
    @test (treeRight(wtest,kara)) == true
    @test (treeFront(wtest,kara)) == true
    # Test get kara
    @test get_kara(wtest) == kara
    place_kara(wtest,10,10)
    @test length(get_kara(wtest)) == 2

    
end

@World path
@World wcompare path
lara = @wcompare get_kara()

@testset "Loading Types" begin
    # Test if loaded worlds are equal
    for i in 1:length(world.world.actors)
        @test world.world.actors[i].actor_definition == wcompare.world.actors[i].actor_definition
        @test world.world.actors[i].location == wcompare.world.actors[i].location
    end
    # Move kara in global world using wrapper
    @test move(kara) == nothing
    @test JuliaKara.JuliaKara_noGUI.get_actors_at_location(
        world.world,
        JuliaKara.JuliaKara_noGUI.Location(4,8 )
    )[1].actor_definition == JuliaKara.JuliaKara_noGUI.ACTOR_DEFINITIONS[:kara]
    # Test all other functions from global scope
    @test turnLeft(kara) == nothing
    @test turnRight(kara) == nothing
    @test putLeaf(kara) == nothing
    @test removeLeaf(kara) == nothing
    @test onLeaf(kara) == false
    @test treeFront(kara) == false
    @test treeRight(kara) == false
    @test treeLeft(kara) == false
    @test mushroomFront(kara) == false
    # Test reset
    reset!(world)
    @test JuliaKara.JuliaKara_noGUI.get_actors_at_location(
        world.world,
        JuliaKara.JuliaKara_noGUI.Location(3,8) 
    )[1].actor_definition == JuliaKara.JuliaKara_noGUI.ACTOR_DEFINITIONS[:kara]
    move(kara)
    store!(world)
    reset!(world)
    @test JuliaKara.JuliaKara_noGUI.get_actors_at_location(
        world.world,
        JuliaKara.JuliaKara_noGUI.Location(4,8) 
    )[1].actor_definition == JuliaKara.JuliaKara_noGUI.ACTOR_DEFINITIONS[:kara]
    # Test other loaded world
    
    @wcompare move(lara)
    @test JuliaKara.JuliaKara_noGUI.get_actors_at_location(
        wcompare.world,
        JuliaKara.JuliaKara_noGUI.Location(4,8) 
    )[1].actor_definition == JuliaKara.JuliaKara_noGUI.ACTOR_DEFINITIONS[:kara]
end

JuliaKara.close(wtest.window)
JuliaKara.close(wcompare.window)
JuliaKara.close(world.window)
end

