mutable struct SpglibDataset
    spacegroup_number::Cint
    hall_number::Cint
    international_symbol::NTuple{11, UInt8}
    hall_symbol::NTuple{17, UInt8}
    choice::NTuple{6, UInt8}
    transformation_matrix::NTuple{9, Float64}
    origin_shift::NTuple{3, Float64}
    n_operations::Cint
    rotations::Ptr{NTuple{9, Cint}}
    translations::Ptr{NTuple{3, Float64}}
    n_atoms::Cint
    wyckoffs::Ptr{Cint}
    site_symmetry_symbols::Ptr{Tuple{7, UInt8}}
    equivalent_atoms::Ptr{Cint}
    mapping_to_primitive::Ptr{Cint}
    n_std_atoms::Cint
    std_lattice::NTuple{9, Float64}
    std_types::Ptr{Cint}
    std_positions::Ptr{NTuple{3, Float64}}
    std_rotation_matrix::NTuple{9, Float64}
    std_mapping_to_primitive::Ptr{Cint}
    pointgroup_symbol::NTuple{6, UInt8}
end

function spg_get_dataset(lattice::Array{Float64, 2},
                         positions::Array{Float64, 2},
                         types::Array{Int64, 1},
                         num_atom::Int64,
                         symprec::Float64)
    num_atom = Base.convert(Cint, num_atom)
    types = Base.convert(Array{Cint, 1}, types)

    return unsafe_load(ccall( (:spg_get_dataset, libsymspg), Ptr{SpglibDataset},
                            ( Ptr{Float64}, Ptr{Float64}, Ptr{Cint}, Cint, Float64 ),
                                lattice, positions, types, num_atom, symprec ))
end

function spgat_get_dataset(lattice::Array{Float64, 2},
                           positions::Array{Float64, 2},
                           types::Array{Int64, 1},
                           num_atom::Int64,
                           symprec::Float64,
                           angle_tolerance::Float64)
    num_atom = Base.convert(Cint, num_atom)
    types = Base.convert(Array{Cint, 1}, types)

    return unsafe_load(ccall( (:spgat_get_dataset, libsymspg), Ptr{SpglibDataset},
                                ( Ptr{Float64}, Ptr{Float64}, Ptr{Cint}, Cint, Float64, Float64 ),
                                    lattice, positions, types, num_atom, symprec, angle_tolerance ))
end

function spg_get_symmetry!(rotation::Array{Cint, 3},
                          translation::Array{Float64, 2},
                          max_size::Int64,
                          lattice::Array{Float64, 2},
                          position::Array{Float64, 2},
                          types::Array{Int64, 1},
                          num_atom::Int64,
                          symprec::Float64)
   #
   max_size = Base.convert(Cint, max_size)
   types = Base.convert(Array{Cint, 1}, types)
   num_atom = Base.convert(Cint, num_atom)

   return ccall((:spg_get_symmetry, libsymspg), Cint,
                (Ptr{Cint}, Ptr{Float64}, Cint, Ptr{Float64}, Ptr{Float64}, Ptr{Cint}, Cint, Float64),
                 rotation, translation, max_size, lattice, position, types, num_atom, symprec)
end

function spgat_get_symmetry!(rotation::Array{Cint, 3},
                            translation::Array{Float64, 2},
                            max_size::Int64,
                            lattice::Array{Float64, 2},
                            position::Array{Float64, 2},
                            types::Array{Int64, 1},
                            num_atom::Int64,
                            symprec::Float64,
                            angle_tolerance::Float64)
   #
   max_size = Base.convert(Cint, max_size)
   types = Base.convert(Array{Cint, 1}, types)
   num_atom = Base.convert(Cint, num_atom)

   return ccall((:spgat_get_symmetry, libsymspg), Cint,
                (Ptr{Cint}, Ptr{Float64}, Cint, Ptr{Float64}, Ptr{Float64}, Ptr{Cint}, Cint, Float64, Float64),
                 rotation, translation, max_size, lattice, position, types, num_atom, symprec, angle_tolerance)
end

# This method not stable at origin C-API
function spg_get_symmetry_with_collinear_spin!(rotation::Array{Cint, 3},
                                              translation::Array{Float64, 2},
                                              equivalent_atoms::Array{Cint, 1},
                                              max_size::Int64,
                                              lattice::Array{Float64, 2},
                                              position::Array{Float64, 2},
                                              types::Array{Int64, 1},
                                              spins::Array{Float64, 1},
                                              num_atom::Int64,
                                              symprec::Float64)
   #
   max_size = Base.convert(Cint, max_size)
   types = Base.convert(Array{Cint, 1}, types)
   num_atom = Base.convert(Cint, num_atom)

   return ccall((:spg_get_symmetry_with_collinear_spin, libsymspg), Cint,
                (Ptr{Cint}, Ptr{Float64}, Ptr{Cint}, Cint, Ptr{Float64}, Ptr{Float64}, Ptr{Cint}, Ptr{Float64}, Cint, Float64),
                 rotation, translation, equivalent_atoms, max_size, lattice, position, types, spins, num_atom, symprec)
end

function spgat_get_symmetry_with_collinear_spin!(rotation::Array{Cint, 3},
                                              translation::Array{Float64, 2},
                                              equivalent_atoms::Array{Cint, 1},
                                              max_size::Int64,
                                              lattice::Array{Float64, 2},
                                              position::Array{Float64, 2},
                                              types::Array{Int64, 1},
                                              spins::Array{Float64, 1},
                                              num_atom::Int64,
                                              symprec::Float64,
                                              angle_tolerance::Float64)
   #
   max_size = Base.convert(Cint, max_size)
   types = Base.convert(Array{Cint, 1}, types)
   num_atom = Base.convert(Cint, num_atom)

   return ccall((:spgat_get_symmetry_with_collinear_spin, libsymspg), Cint,
                (Ptr{Cint}, Ptr{Float64}, Ptr{Cint}, Cint, Ptr{Float64}, Ptr{Float64}, Ptr{Cint}, Ptr{Float64}, Cint, Float64, Float64),
                 rotation, translation, equivalent_atoms, max_size, lattice, position, types, spins, num_atom, symprec, angle_tolerance)
end

function spg_get_hall_number_from_symmetry(rotation::Array{Cint, 3},
                                  translation::Array{Float64, 2},
                                  num_operations::Int64,
                                  symprec::Float64)
    #
    num_operations = Base.convert(Cint, num_operations)

    return ccall((:spg_get_hall_number_from_symmetry, libsymspg), Cint,
                    (Ptr{Cint}, Ptr{Float64}, Cint, Float64),
                    rotation, translation, num_operations, symprec)
end

function spg_get_multiplicity(lattice::Array{Float64, 2},
                     position::Array{Float64, 2},
                     types::Array{Int64, 1},
                     num_atom::Int64,
                     symprec::Float64)
    #
    types = Base.convert(Array{Cint, 1}, types)
    num_atom = Base.convert(Cint, num_atom)

    return ccall((:spg_get_multiplicity, libsymspg), Cint,
                (Ptr{Float64}, Ptr{Float64}, Ptr{Cint}, Cint, Float64),
                 lattice, position, types, num_atom, symprec)
end

function spgat_get_multiplicity(lattice::Array{Float64, 2},
                     position::Array{Float64, 2},
                     types::Array{Int64, 1},
                     num_atom::Int64,
                     symprec::Float64,
                     angle_tolerance::Float64)
    #
    types = Base.convert(Array{Cint, 1}, types)
    num_atom = Base.convert(Cint, num_atom)

    return ccall((:spgat_get_multiplicity, libsymspg), Cint,
                (Ptr{Float64}, Ptr{Float64}, Ptr{Cint}, Cint, Float64, Float64),
                 lattice, position, types, num_atom, symprec, angle_tolerance)
end
