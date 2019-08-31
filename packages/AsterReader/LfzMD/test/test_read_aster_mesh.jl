# This file is a part of JuliaFEM.
# License is MIT: see https://github.com/JuliaFEM/AsterReader.jl/blob/master/LICENSE

using FEMBase, Test, AsterReader
using AsterReader: aster_parse_nodes, aster_read_mesh, MEDFile, get_element_sets

datadir = first(splitext(basename(@__FILE__)))

@testset "parse nodes from ascii file" begin
    section = """
    N9  2.0 3.0 4.0
    COOR_3D
    N1          0.0 0.0 0.0
    N2          1.0 0.0 0.0
    N3          1.0 1.0 0.0
    N4          0.0 1.0 0.0
    N5          0.0 0.0 1.0
    N6          1.0 0.0 1.0
    N7          1.0 1.0 1.0
    N8          0.0 1.0 1.0
    FINSF
    absdflasdf
    N12 3.0 4.0 5.0 6.0
    N13 3.0 4.0 5.0
    """
    nodes = aster_parse_nodes(section)
    @test nodes[1] == Float64[0.0, 0.0, 0.0]
    @test nodes[8] == Float64[0.0, 1.0, 1.0]
    @test length(nodes) == 8
end

@testset "read mesh med file (mesh not found)" begin
    med = AsterReader.MEDFile(joinpath(datadir, "quad4.med"))
    @test_throws ErrorException AsterReader.get_mesh(med, "notfound")
end

@testset "read element sets (element sets not found)" begin
    med = AsterReader.MEDFile(joinpath(datadir, "quad4.med"))
    delete!(med.data["FAS"]["BLOCK"], "ELEME")
    @test isempty(AsterReader.get_element_sets(med, "BLOCK"))
end

@testset "read med file with several mesh files" begin
    med = AsterReader.MEDFile(joinpath(datadir, "quad4.med"))
    med.data["FAS"]["new_mesh"] = med.data["FAS"]["BLOCK"]
   @test_throws ErrorException AsterReader.aster_read_mesh_(med)
end

@testset "read mesh med file" begin
    meshfile = joinpath(datadir, "quad4.med")
    mesh = aster_read_mesh(meshfile)
    @test length(mesh["element_sets"]) == 5
    @test length(mesh["node_sets"]) == 4
    @test length(mesh["elements"]) == 5
    @test length(mesh["nodes"]) == 4
    for elset in ["BLOCK", "TOP", "BOTTOM", "LEFT", "RIGHT"]
        @test haskey(mesh["element_sets"], elset)
        @test length(mesh["element_sets"][elset]) == 1
    end
    for nset in ["TOP_LEFT", "TOP_RIGHT", "BOTTOM_LEFT", "BOTTOM_RIGHT"]
        @test haskey(mesh["node_sets"], nset)
        @test length(mesh["node_sets"][nset]) == 1
    end
end

@testset "test read element sets from med file, issue #111 at JuliaFEM.jl" begin
    meshfile = joinpath(datadir, "hexmeshOverlappingGroups.med")
    med = MEDFile(meshfile)
    element_sets = get_element_sets(med, "Mesh_1")
    @test element_sets[-10] == ["halfhex", "mosthex"]
    @test element_sets[-11] == ["halfhex"]
end

@testset "test read overlapping ets, issue #111 at JuliaFEM.jl" begin
    mesh_file = joinpath(datadir, "hexmeshOverlappingGroups.med")
    mesh = aster_read_mesh(mesh_file, "Mesh_1")
    @test length(mesh["element_sets"]["mosthex"]) == 273
    @test length(mesh["element_sets"]["halfhex"]) == 147
end
