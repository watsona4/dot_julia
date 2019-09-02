module kara_xml

using Test
include("../src/JuliaKara_noGUI.jl"); using .JuliaKara_noGUI

@testset "JuliaKara XML" begin
    path = joinpath(@__DIR__,"..","test","example.world")
    load_world = kara_xml.JuliaKara_noGUI.xml_load_world(path)
    act = load_world.actors
    
    @test JuliaKara_noGUI.get_actors_at_location(load_world,JuliaKara_noGUI.Location(7, 8))[1].actor_definition == JuliaKara_noGUI.ACTOR_DEFINITIONS[:tree]
    @test JuliaKara_noGUI.get_actors_at_location(load_world,JuliaKara_noGUI.Location(7, 7))[1].actor_definition == JuliaKara_noGUI.ACTOR_DEFINITIONS[:tree]
    @test JuliaKara_noGUI.get_actors_at_location(load_world,JuliaKara_noGUI.Location(7, 6))[1].actor_definition == JuliaKara_noGUI.ACTOR_DEFINITIONS[:tree]
    @test JuliaKara_noGUI.get_actors_at_location(load_world,JuliaKara_noGUI.Location(3, 5))[1].actor_definition == JuliaKara_noGUI.ACTOR_DEFINITIONS[:mushroom]
    @test JuliaKara_noGUI.get_actors_at_location(load_world,JuliaKara_noGUI.Location(3, 4))[1].actor_definition == JuliaKara_noGUI.ACTOR_DEFINITIONS[:mushroom]
    @test JuliaKara_noGUI.get_actors_at_location(load_world,JuliaKara_noGUI.Location(3, 3))[1].actor_definition == JuliaKara_noGUI.ACTOR_DEFINITIONS[:mushroom]
    @test JuliaKara_noGUI.get_actors_at_location(load_world,JuliaKara_noGUI.Location(7, 3))[1].actor_definition == JuliaKara_noGUI.ACTOR_DEFINITIONS[:leaf]
    @test JuliaKara_noGUI.get_actors_at_location(load_world,JuliaKara_noGUI.Location(8, 3))[1].actor_definition == JuliaKara_noGUI.ACTOR_DEFINITIONS[:leaf]
    @test JuliaKara_noGUI.get_actors_at_location(load_world,JuliaKara_noGUI.Location(9, 3))[1].actor_definition == JuliaKara_noGUI.ACTOR_DEFINITIONS[:leaf]
    @test JuliaKara_noGUI.get_actors_at_location(load_world,JuliaKara_noGUI.Location(3, 8))[1].actor_definition == JuliaKara_noGUI.ACTOR_DEFINITIONS[:kara]
    
    path_save = joinpath(@__DIR__,"..","test","example_save.world")
    kara_xml.JuliaKara_noGUI.xml_save_world(load_world,path_save)
    @test isfile(path_save) == true
    rm(path_save)
    @test isfile(path_save) == false
end

end
