using Test

@testset "transfinite rectangle" begin
    fname = tempname() * ".msh"
    nx, ny = 10, 7
    coefx, coefy = 1.2, 1.2
    @gmsh_do begin
        @addPoint begin
            -1.0, -1.0, 0.0, 0.0, 1
            1.0, -1.0, 0.0, 0.0, 2
            1.0, 1.0, 0.0, 0.0, 3
            -1.0, 1.0, 0.0, 0.0, 4
        end
        @addLine begin
            1, 2
            2, 3
            4, 3
            1, 4
        end
        gmsh.model.geo.addCurveLoop([1, 2, -3, -4], 1)
        gmsh.model.geo.addPlaneSurface([1], 1)
        gmsh.model.geo.mesh.setTransfiniteSurface(1, "Left", [1, 2, 3, 4])
        @setTransfiniteCurve begin
            1, nx+1, "Progression", coefx
            3, nx+1, "Progression", coefx
            2, ny+1, "Progression", coefy
            4, ny+1, "Progression", coefy
        end
        gmsh.model.geo.mesh.setRecombine(2, 1)
        gmsh.model.geo.synchronize()
        gmsh.model.mesh.generate(2)
        gmsh.write(fname)
    end

    els = @gmsh_open fname begin
        gmsh.model.mesh.getElements(2)
    end
    @test els[1][1] == 3
    @test length(els[2][1]) == nx * ny
    rm(fname)
end

@testset "adaptive mesh with field" begin
    fname = tempname() * ".msh"
    @gmsh_do begin
        factory = gmsh.model.geo
        @addPoint begin
            0.0, 0.0, 0.0, 0.0, 1
            1.0, 0.0, 0.0, 0.0, 2
            1.0, 1.0, 0.0, 0.0, 3
            0.0, 1.0, 0.0, 0.0, 4
        end
        @addLine begin
            1, 2, 1
            2, 3, 2
            3, 4, 3
            4, 1, 4
        end
        factory.addCurveLoop([1, 2, 3, 4], 1)
        factory.addPlaneSurface([1], 1)
        @addField 1 "Distance" begin
            "EdgesList", [2]
            "NNodesByEdge", 100
        end
        @addField 2 "Threshold" begin
            "IField", 1
            "LcMin", 0.005
            "LcMax", 0.15
            "DistMin", 0.15
            "DistMax", 0.50
        end
        @addField 3 "MathEval" begin
            "F", "0.01*(1.0+50.*(y-x*x)*(y-x*x) + (1-x)*(1-x))"
        end
        @addField 4 "Distance" begin
            "NodesList", [4]
        end
        @addField 5 "MathEval" begin
            "F", "F4^3 + 0.005"
        end
        @addField 6 "Min" begin
            "FieldsList", [2, 3, 5]
        end
        gmsh.model.mesh.field.setAsBackgroundMesh(6)
        gmsh.model.geo.synchronize()
        gmsh.model.mesh.generate(2)
        gmsh.write(fname)
    end

    els = @gmsh_open fname begin
        gmsh.model.mesh.getElements(2)
    end
    @test els[1][1] == 2 # 3-node triangle
    @test !isempty(els[2][1])
    rm(fname)
end

@testset "option of terminal output" begin
    _stdout = stdout
    rd, wr = redirect_stdout()
    @gmsh_do begin
        factory = gmsh.model.geo
        @addOption begin
            "General.Terminal", 1
            "Mesh.CharacteristicLengthMax", 0.4
            "Mesh.CharacteristicLengthMin", 0.1
        end

        @addPoint begin
            0.0, 0.0, 0.0, 0.1, 1
            0.0, 1.0, 0.0, 0.3, 2
            1.0, 1.0, 0.0, 0.2, 3
            1.0, 0.0, 0.0, 0.4, 4
        end
        @addLine begin
            1, 2, 1
            2, 3, 2
            3, 4, 3
            4, 1, 4
        end
        factory.addCurveLoop([1, 2, 3, 4], 1)
        factory.addPlaneSurface([1], 1)
        gmsh.model.geo.synchronize()
        gmsh.model.mesh.generate(2)
        gmsh.write("temp.msh")
    end
    redirect_stdout(_stdout)
    close(wr)
    output = read(rd, String)
    close(rd)
    @test occursin("Done meshing", output)
end
