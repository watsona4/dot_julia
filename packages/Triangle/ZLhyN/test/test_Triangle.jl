@testset "Triangle.jl Interface" begin
    @testset "Basic Triangulation" begin
        
        @testset "basic_triangulation_vertices" begin
            points = Array{Float64,2}([0. 0.; 1. 0.; 0. 1.])
            @test Triangle.basic_triangulation_vertices(points)[1] == points
        end
        
        @testset "basic_triangulation with point map" begin
            points = Array{Float64,2}([0. 0.; 1. 0.; 0. 1.])
            points_map = [1, 2, 3]
            @test Triangle.basic_triangulation(points,points_map)[1] == points_map
        end

        @testset "basic_triangulation_vertices with point map" begin
            points = Array{Float64,2}([0. 0.; 1. 0.; 0. 1.])
            points_map = [1, 2, 3]
            @test Triangle.basic_triangulation_vertices(points,points_map)[1] == points
        end

        # Triforce
        @testset "basic_triangulation with unordered point map" begin
            points = Array{Float64,2}([0. 0.; 4. 0.; 2. 3.; 8. 0.; 6. 3.; 4. 6.])
            points_map = [1, 2, 4, 3, 5, 6]
            result_tri = [[1, 2, 4],[4, 2, 5],[5, 6, 4],[3, 5, 2]]
            @test Triangle.basic_triangulation(points,points_map) == result_tri
        end        

        # Tetris L (no boundary)
        @testset "basic_triangulation on L tetris piece" begin
            points = [0. 0.; 0. 3.; 1. 3.; 1. 1.; 2. 1.; 2. 0.]
            points_map = Array{Int64,1}(collect(1:1:size(points)[1]))
            triangles = Triangle.basic_triangulation(points,points_map)
            @test length(triangles) == 5
        end

        @testset "basic_triangulation_vertices with point map on L tetris piece" begin
            points = [0. 0.; 0. 3.; 1. 3.; 1. 1.; 2. 1.; 2. 0.]
            points_map = Array{Int64,1}(collect(1:1:size(points)[1]))
            triangles = Triangle.basic_triangulation_vertices(points,points_map)
            @test length(triangles) == 5
        end  

         # Tetris L (all boundary)
        @testset "constrained_triangulation" begin
            points = [0. 0.; 0. 3.; 1. 3.; 1. 1.; 2. 1.; 2. 0.]
            points_map = Array{Int64,1}(collect(1:1:size(points)[1]))
            edges_list = Array{Int64,2}([1 2; 2 3; 3 4; 4 5; 5 6; 6 1])
            triangles = Triangle.constrained_triangulation(points,points_map,edges_list)
            @test length(triangles) == 4
        end

        @testset "constrained_triangulation_vertices" begin
            points = [0. 0.; 0. 3.; 1. 3.; 1. 1.; 2. 1.; 2. 0.]
            points_map = Array{Int64,1}(collect(1:1:size(points)[1]))
            edges_list = Array{Int64,2}([1 2; 2 3; 3 4; 4 5; 5 6; 6 1])
            triangles = Triangle.constrained_triangulation_vertices(points,points_map,edges_list)
            @test length(triangles) == 4
        end        

        # Tetris L (custom boundary)
        @testset "constrained_triangulation with boundary" begin
            points = [0. 0.; 0. 3.; 1. 3.; 1. 1.; 2. 1.; 2. 0.]
            points_map = Array{Int64,1}(collect(1:1:size(points)[1]))
            edges_list = Array{Int64,2}([1 2; 2 3; 3 4; 4 5; 5 6; 6 1])
            edge_boundary = [false, false, true, true, false, false]
            triangles = Triangle.constrained_triangulation(points,points_map,edges_list,edge_boundary)
            @test length(triangles) == 4
        end

        @testset "constrained_triangulation_vertices with boundary" begin
            points = [0. 0.; 0. 3.; 1. 3.; 1. 1.; 2. 1.; 2. 0.]
            points_map = Array{Int64,1}(collect(1:1:size(points)[1]))
            edges_list = Array{Int64,2}([1 2; 2 3; 3 4; 4 5; 5 6; 6 1])
            edge_boundary = [false, false, true, true, false, false]
            triangles = Triangle.constrained_triangulation_vertices(points,points_map,edges_list,edge_boundary)
            @test length(triangles) == 4
        end

        # Triforce (without center triangle)
        @testset "constrained_triangulation with boundary and holes" begin
            points = [0. 0.; 4. 0.; 2. 3.; 8. 0.; 6. 3.; 4. 6.]
            points_map = Array{Int64,1}(collect(1:1:size(points)[1]))
            edges_list = Array{Int64,2}([1 2; 2 3; 3 1; 2 4; 4 5; 5 2; 3 5; 5 6; 6 3])
            edge_boundary = [false,true,false,false,false,true,true,false,false]
            holes_list = [4. 2.]
            triangles = Triangle.constrained_triangulation(points,points_map,edges_list,edge_boundary,holes_list)
            @test length(triangles) == 3
        end

        @testset "constrained_triangulation_vertices with boundary and holes" begin
            points = [0. 0.; 4. 0.; 2. 3.; 8. 0.; 6. 3.; 4. 6.]
            points_map = Array{Int64,1}(collect(1:1:size(points)[1]))
            edges_list = Array{Int64,2}([1 2; 2 3; 3 1; 2 4; 4 5; 5 2; 3 5; 5 6; 6 3])
            edge_boundary = [false,true,false,false,false,true,true,false,false]
            holes_list = [4. 2.]
            triangles = Triangle.constrained_triangulation_vertices(points,points_map,edges_list,edge_boundary,holes_list)
            @test length(triangles) == 3
        end                           
    end
end
