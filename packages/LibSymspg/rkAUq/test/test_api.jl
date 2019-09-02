@testset "version" begin
    @test isa(LibSymspg.spg_get_major_version(), Int64)
    @test isa(LibSymspg.spg_get_minor_version(), Int64)
    @test isa(LibSymspg.spg_get_micro_version(), Int64)
end

@testset "SpglibSpacegroupType" begin
    spacegroup_type = LibSymspg.spg_get_spacegroup_type(101)
    @test spacegroup_type.number == 15
    @test LibSymspg.char2Str(spacegroup_type.hall_symbol) == "-I 2a"
    @test LibSymspg.char2Str(spacegroup_type.arithmetic_crystal_class_symbol) == "2/mC"
end

@testset "SpglibDataset" begin
    latt = [4.0 0.0 0.0; 2.0 3.4641 0.0; 0.0 0.0 12.0]
    positions = [0.0 1/3; 0.0 1/3; 0.0 1/3]
    types = [1, 1]
    num_atom = 2
    db = LibSymspg.spg_get_dataset(latt, positions, types, num_atom, 1e-3)
    @test LibSymspg.char2Str(db.international_symbol) == "P-3m1"

    nop = db.n_operations
    @test nop == 12
    r_ = unsafe_wrap(Array{NTuple{9, Cint}}, db.rotations, nop)
    r = LibSymspg.rotsFromTuple(r_, nop)
    @test size(r) == (3, 3, 12)
    t_ = unsafe_wrap(Array{NTuple{3, Float64}}, db.translations, nop)
    t = LibSymspg.transFromTuple(t_, nop)
    @test size(t) == (3, 12)

    @test LibSymspg.char2Str(db.pointgroup_symbol) == "-3m"
end

@testset "Get Symmetry Ops" begin
    latt = [4.0 0.0 0.0;
            0.0 4.0 0.0;
            0.0 0.0 4.0]
    positions = [0.0 0.5; 0.0 0.5; 0.0 0.5]
    types = [1, 1]
    num_atom = 2

    # will be used after
    max_size = num_atom*48
    rots = Array{Cint, 3}(undef, 3, 3, max_size)
    trans = Array{Float64, 2}(undef, 3, max_size)

    _ = LibSymspg.spg_get_symmetry!(rots, trans, max_size, latt, positions, types, num_atom, 1e-5)
    @test size(rots) == (3, 3, 96)
    @test size(trans) == (3, 96)

    hall_number = LibSymspg.spg_get_hall_number_from_symmetry(rots, trans, max_size, 1e-5)
    @test hall_number == 529

    latt = [4.0 0.0 0.0;
            0.0 4.0 0.0;
            0.0 0.0 4.0]
    positions = [0.0 0.5; 0.0 0.5; 0.0 0.5]
    types = [1, 1]
    equivalent_atoms = Base.convert(Array{Cint, 1}, [0, 0])
    spins = [1.0, -2.0]
    num_atom = 2

    max_size = num_atom*48
    rots = Array{Cint, 3}(undef, 3, 3, max_size)
    trans = Array{Float64, 2}(undef, 3, max_size)
    _ = LibSymspg.spg_get_symmetry_with_collinear_spin!(rots, trans, equivalent_atoms, max_size,
                                                        latt, positions, types, spins, num_atom, 1e-5)
    @test equivalent_atoms == [0, 1]

    latt = [4.0 0.0 0.0;
            0.0 4.0 0.0;
            0.0 0.0 4.0]
    positions = [0.0 0.5; 0.0 0.5; 0.0 0.5]
    types = [1, 1]
    num_atom = 2
    @test LibSymspg.spg_get_multiplicity(latt, positions, types, num_atom, 1e-5) == 96
end

@testset "lattice reduce" begin
    latt = [4.0 20.0 0.0; 0.0 2.0 0.0; 0.0 0.0 12.0]
    LibSymspg.spg_niggli_reduce!(latt, 1e-3)
    @test latt ≈ [0.0 -2.0 0.0; 4.0 0.0 0.0; 0.0 0.0 12.0]

    latt = [4.0 20.0 0.0; 0.0 2.0 0.0; 0.0 0.0 12.0]
    LibSymspg.spg_delaunay_reduce!(latt, 1e-3)
    @test latt ≈ [0.0 2.0 0.0; -4.0 -0.0 0.0; -0.0 -0.0 12.0]
end

@testset "reciprocal mesh" begin
    latt = [-2.0 2.0 2.0; 2.0 -2.0 2.0; 2.0 2.0 -2.0]
    positions = Array{Float64, 2}([0.0 0.0 0.0]')
    types = [1]
    na = 1
    mesh = [4, 4, 4]
    is_shift = [0, 0, 0]
    nir, grid_address, ir_mapping_table =
        LibSymspg.spg_get_ir_reciprocal_mesh(mesh, is_shift, 1, latt, positions, types, na, 1e-5)
    @test nir == 8
end

# @testset "reciprocal mesh" begin
#     latt = [0.0 5.0 5.0; 5.0 0.0 5.0; 5.0 5.0 0.0]
#     positions = Array{Float64, 2}([0.0 0.25; 0.0 0.25; 0.0 0.25])
#     types = [1, 1]
#     na = 2
#     mesh = [3,3,3]
#     is_shift = [1,1,1]
#     nir, grid_address, ir_mapping_table =
#         LibSymspg.spg_get_ir_reciprocal_mesh(mesh, is_shift, 1, latt, positions, types, na, 1e-5)
#     @test nir == 4
# end

@testset "Cell reduce standardize" begin
    latt = [4.0 0.0 0.0;
            0.0 4.0 0.0;
            0.0 0.0 4.0]
    positions = [0.0 0.5; 0.0 0.5; 0.0 0.5]
    types = [1, 1]
    new_latt, new_positions, new_types = LibSymspg.spg_find_primitive(latt, positions, types, 1e-5)
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
    latt, positions, types = LibSymspg.spg_refine_cell(latt, positions, types, 1e-5)
    @test latt ≈ [4.0 0.0 0.0; 0.0 4.0 0.0; 0.0 0.0 4.0]
    @test positions ≈ [0.0 0.5; 0.0 0.5; 0.0 0.5]
    @test types == [1, 1]
end
