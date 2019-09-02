using Test
using LibSymspg

include("test_api.jl")

@testset "Cell standardize(export)" begin
    latt = [4.0 0.0 0.0;
            0.0 4.0 0.0;
            0.0 0.0 4.0]
    positions = [0.0 0.5; 0.0 0.5; 0.0 0.5]
    types = [1, 1]
    new_latt, new_positions, new_types = find_primitive(latt, positions, types, 1e-5)
    # test arguments not modified
    @test latt ≈ [4.0 0.0 0.0; 0.0 4.0 0.0; 0.0 0.0 4.0]
    @test positions ≈ [0.0 0.5; 0.0 0.5; 0.0 0.5]
    @test types == [1, 1]

    @test new_latt ≈ [-2.0 2.0 2.0; 2.0 -2.0 2.0; 2.0 2.0 -2.0]
    @test new_positions ≈ [0.0, 0.0, 0.0]
    @test new_types == [1]

    latt = [-2.0 2.0 2.0; 2.0 -2.0 2.0; 2.0 2.0 -2.0]
    positions = Array{Float64, 2}([0.0 0.0 0.0]')
    types = [1]
    latt, positions, types = refine_cell(latt, positions, types, 1e-5)
    @test latt ≈ [4.0 0.0 0.0; 0.0 4.0 0.0; 0.0 0.0 4.0]
    @test positions ≈ [0.0 0.5; 0.0 0.5; 0.0 0.5]
    @test types == [1, 1]
end

@testset "lattice reduce(export)" begin
    latt = [4.0 20.0 0.0; 0.0 2.0 0.0; 0.0 0.0 12.0]
    niggli_reduce!(latt, 1e-3)
    @test latt ≈ [0.0 -2.0 0.0; 4.0 0.0 0.0; 0.0 0.0 12.0]

    latt = [4.0 20.0 0.0; 0.0 2.0 0.0; 0.0 0.0 12.0]
    delaunay_reduce!(latt, 1e-3)
    @test latt ≈ [0.0 2.0 0.0; -4.0 -0.0 0.0; -0.0 -0.0 12.0]
end

# @testset "reciprocal mesh(export)" begin
#     latt = [5.0 0.0 5.0; 0.0 5.0 5.0; 5.0 5.0 0.0]
#     positions = Array{Float64, 2}([0.0 0.25; 0.0 0.25; 0.0 0.25])
#     types = [1, 1]
#     na = 2
#     mesh = [3,3,3]
#     is_shift = [true,true,true]
#     nir, grid_address, ir_mapping_table =
#         ir_reciprocal_mesh(mesh, is_shift, true, latt, positions, types, na, 1e-5)
#     @test nir == 4
# end

@testset "symmetry(export)" begin
    latt = [4.0 0.0 0.0; 2.0 3.4641 0.0; 0.0 0.0 12.0]
    positions = [0.0 1/3; 0.0 1/3; 0.0 1/3]
    types = [1, 1]
    num_atom = 2
    @test get_spacegroup(latt, positions, types, num_atom) == ("P-3m1", 164)

    rots, trans = get_symmetry(latt, positions, types, 1e-3)
    @test size(rots) == (3, 3, 12)
    @test size(trans) == (3, 12)
end
