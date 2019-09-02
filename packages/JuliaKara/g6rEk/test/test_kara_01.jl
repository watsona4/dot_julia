module kara_ex01
using Test
include("../src/JuliaKara_noGUI.jl"); using .JuliaKara_noGUI

@testset "JuliaKara Example 01" begin
    wtest = World(10,10)
    kara = place_kara(wtest,4,4)

    function nextTest(world,kara)
        turnRight(world,kara)
        move(world,kara)
        turnLeft(world,kara)
    end

    place_tree(wtest,4,5)
    place_tree(wtest,5,6)
    place_mushroom(wtest,5,5)
    place_mushroom(wtest,6,5)
    place_mushroom(wtest,6,6)
    place_mushroom(wtest,7,5)
    place_leaf(wtest,8,5)

    @test_throws JuliaKara_noGUI.ActorInvalidMovementError move(wtest,kara)
    nextTest(wtest,kara)
    @test_throws JuliaKara_noGUI.ActorInvalidMovementError move(wtest,kara)
    nextTest(wtest,kara)
    @test_throws JuliaKara_noGUI.ActorInvalidMultipleMovementError move(wtest,kara)
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
    @test_throws JuliaKara_noGUI.ActorGrabNotFoundError removeLeaf(wtest,kara)
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

@testset "JuliaKara Bounds" begin
    w = World(3,3)
    k = place_kara(w,1,1)
    move(w,k)
    move(w,k)
    move(w,k)
    @test k.location == JuliaKara_noGUI.ActorsWorld.Location(1,1)
    turnRight(w,k)
    turnRight(w,k)
    move(w,k)
    @test k.location == JuliaKara_noGUI.ActorsWorld.Location(1,3)
    turnRight(w,k)
    move(w,k)
    @test k.location == JuliaKara_noGUI.ActorsWorld.Location(3,3)
    turnRight(w,k)
    turnRight(w,k)
    move(w,k)
    @test k.location == JuliaKara_noGUI.ActorsWorld.Location(1,3)
end

end
