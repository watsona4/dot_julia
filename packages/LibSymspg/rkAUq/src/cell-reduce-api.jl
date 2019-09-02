"""
"""
function spg_standardize_cell(lattice::Array{Float64, 2},
                              positions::Array{Float64, 2},
                              types::Array{Int64, 1},
                              num_atom::Int64,
                              to_primitive::Int64,
                              no_idealize::Int64,
                              symprec::Float64)
    # transpose to colomn vector used by spglib
    lattice_ = copy(lattice)
    positions_ = copy(positions)

    allocN = 4
    positions_ = zeros(Float64, 3, num_atom*allocN)
    types_ = zeros(Int64, num_atom*allocN)

    positions_[:, 1:num_atom] = positions[:, :]
    types_[1:num_atom] = types

    types_ = Base.cconvert(Array{Int32, 1}, types_)
    num_atom = Base.cconvert(Int32, num_atom)
    to_primitive = Base.cconvert(Int32, to_primitive)
    no_idealize = Base.cconvert(Int32, no_idealize)

    num_primitive_atom =
    ccall( (:spg_standardize_cell, libsymspg), Int32,
           ( Ptr{Float64}, Ptr{Float64}, Ptr{Int32}, Int32, Int32, Int32, Float64 ),
           lattice_, positions_, types_, num_atom, to_primitive, no_idealize, symprec )

    positions = positions_[:, 1:num_primitive_atom]
    types = types_[1:num_primitive_atom]

    return lattice_, positions, Base.cconvert(Array{Int64, 1}, types), Base.cconvert(Int64,num_primitive_atom)
end

function spg_standardize_cell(lattice::Array{Float64, 2},
                              positions::Array{Float64, 2},
                              types::Array{Int64, 1},
                              to_primitive::Bool,
                              no_idealize::Bool,
                              symprec::Float64)

    to_primitive ? to_primitive_ = 1 : to_primitive_ = 0
    no_idealize ? no_idealize_ = 1 : no_idealize_ = 0

    num_atom = size(types)[1]

    return spg_standardize_cell(lattice, positions, types, num_atom, to_primitive_, no_idealize_, symprec)
end

function spg_find_primitive(lattice::Array{Float64, 2},
                            positions::Array{Float64, 2},
                            types::Array{Int64, 1},
                            symprec::Float64)

    return spg_standardize_cell(lattice, positions, types, true, false, symprec)
end

function spg_refine_cell(lattice::Array{Float64, 2},
                         positions::Array{Float64, 2},
                         types::Array{Int64, 1},
                         symprec::Float64)

    return spg_standardize_cell(lattice, positions, types, false, false, symprec)
end

"""
angle_tolerance
"""
function spgat_standardize_cell(lattice::Array{Float64, 2},
                              positions::Array{Float64, 2},
                              types::Array{Int64, 1},
                              num_atom::Int64,
                              to_primitive::Int64,
                              no_idealize::Int64,
                              symprec::Float64,
                              angle_tolerance::Float64)
    # transpose to colomn vector used by spglib
    lattice_ = copy(lattice)
    positions_ = copy(positions)

    allocN = 4
    positions_ = zeros(Float64, 3, num_atom*allocN)
    types_ = zeros(Int64, num_atom*allocN)

    positions_[:, 1:num_atom] = positions[:, :]
    types_[1:num_atom] = types

    types_ = Base.cconvert(Array{Int32, 1}, types_)
    num_atom = Base.cconvert(Int32, num_atom)
    to_primitive = Base.cconvert(Int32, to_primitive)
    no_idealize = Base.cconvert(Int32, no_idealize)

    num_primitive_atom =
    ccall( (:spgat_standardize_cell, libsymspg), Int32,
           ( Ptr{Float64}, Ptr{Float64}, Ptr{Int32}, Int32, Int32, Int32, Float64, Float64 ),
           lattice_, positions_, types_, num_atom, to_primitive, no_idealize, symprec, angle_tolerance )

    positions = positions_[:, 1:num_primitive_atom]
    types = types_[1:num_primitive_atom]

    return lattice_, positions, Base.cconvert(Array{Int64, 1}, types), Base.cconvert(Int64,num_primitive_atom)
end

function spgat_standardize_cell(lattice::Array{Float64, 2},
                              positions::Array{Float64, 2},
                              types::Array{Int64, 1},
                              to_primitive::Bool,
                              no_idealize::Bool,
                              symprec::Float64,
                              angle_tolerance::Float64)

    to_primitive ? to_primitive_ = 1 : to_primitive_ = 0
    no_idealize ? no_idealize_ = 1 : no_idealize_ = 0

    num_atom = size(types)[1]

    return spgat_standardize_cell(lattice, positions, types, num_atom, to_primitive_, no_idealize_, symprec, angle_tolerance)
end

function spgat_find_primitive(lattice::Array{Float64, 2},
                            positions::Array{Float64, 2},
                            types::Array{Int64, 1},
                            symprec::Float64,
                            angle_tolerance::Float64)

    return spgat_standardize_cell(lattice, positions, types, true, false, symprec, angle_tolerance)
end

function spgat_refine_cell(lattice::Array{Float64, 2},
                         positions::Array{Float64, 2},
                         types::Array{Int64, 1},
                         symprec::Float64,
                         angle_tolerance::Float64)

    return spgat_standardize_cell(lattice, positions, types, false, false, symprec, angle_tolerance)
end
