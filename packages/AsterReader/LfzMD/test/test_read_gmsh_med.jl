# This file is a part of JuliaFEM.
# License is MIT: see https://github.com/JuliaFEM/AsterReader.jl/blob/master/LICENSE

using FEMBase, Test, AsterReader
using AsterReader: aster_parse_nodes, aster_read_mesh, MEDFile, get_element_sets

datadir = first(splitext(basename(@__FILE__)))

@testset "test med file exported from gmsh, issue #16" begin
    mesh_file = joinpath(datadir, "t1.med")
    mesh = aster_read_mesh(mesh_file)
end
