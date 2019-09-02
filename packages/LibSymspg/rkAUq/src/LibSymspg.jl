module LibSymspg
using Libdl

# Load in `deps.jl`, complaining if it does not exist
const depsjl_path = joinpath(@__DIR__, "..", "deps", "deps.jl")
if !isfile(depsjl_path)
    error("LibSymspg not installed properly, run Pkg.build(\"LibSymspg\"), restart Julia and try again")
end
include(depsjl_path)

# Module initialization function
function __init__()
    # Always check your dependencies from `deps.jl`
    check_deps()
end

export find_primitive, refine_cell,
        niggli_reduce!, delaunay_reduce!,
        ir_reciprocal_mesh,
        get_spacegroup, get_symmetry

include("version.jl")
include("symmetry-api.jl")
include("spacegroup-api.jl")
include("cell-reduce-api.jl")
include("latt-reduce-api.jl")
include("ir-mesh-api.jl")
include("utils.jl")


"""
return type: String, Int64 -> (symbol, spg_number)
"""
function get_spacegroup(lattice::Array{Float64, 2},
                         positions::Array{Float64, 2},
                         types::Array{Int64, 1},
                         num_atom::Int64,
                         symprec::Float64=1e-5)
    #
    db = spg_get_dataset(lattice, positions, types, num_atom, symprec)
    return char2Str(db.international_symbol), Base.convert(Int64, db.spacegroup_number)
end

"""
get_symmetry
"""
function get_symmetry(lattice::Array{Float64, 2},
                      positions::Array{Float64, 2},
                      types::Array{Int64, 1},
                      num_atom::Int64,
                      symprec::Float64=1e-5)
    #
    max_size = 48*num_atom
    rots = Array{Cint, 3}(undef, 3, 3, max_size)
    trans = Array{Float64, 2}(undef, 3, max_size)

    nop = spg_get_symmetry!(rots, trans, max_size, lattice, positions, types, num_atom, symprec)
    @assert nop ≠ 0

    return Base.convert(Array{Int64, 3}, rots[:,:,1:nop]), trans[:,1:nop]
end

function get_symmetry(lattice::Array{Float64, 2},
                      positions::Array{Float64, 2},
                      types::Array{Int64, 1},
                      symprec::Float64=1e-5)
    #
    @assert size(positions)[2] == size(types)[1]
    num_atom = size(types)[1]

    return get_symmetry(lattice, positions, types, num_atom, symprec)
end
"""
"""
find_primitive(lattice::Array{Float64, 2},
               positions::Array{Float64, 2},
               types::Array{Int64, 1},
               symprec::Float64) =
    spg_find_primitive(lattice, positions, types, symprec)

find_primitive(lattice::Array{Float64, 2},
                positions::Array{Float64, 2},
                types::Array{Int64, 1},
                symprec::Float64,
                angle_tolerance::Float64) =
    spgat_find_primitive(lattice, positions, types, symprec, angle_tolerance)

"""
"""
refine_cell(lattice::Array{Float64, 2},
            positions::Array{Float64, 2},
            types::Array{Int64, 1},
            symprec::Float64) =
    spg_refine_cell(lattice, positions, types, symprec)

refine_cell(lattice::Array{Float64, 2},
            positions::Array{Float64, 2},
            types::Array{Int64, 1},
            symprec::Float64,
            angle_tolerance::Float64) =
    spgat_refine_cell(lattice, positions, types, symprec, angle_tolerance)

"""
"""
niggli_reduce! = spg_niggli_reduce!

"""
"""
delaunay_reduce! = spg_delaunay_reduce!

"""
"""
function ir_reciprocal_mesh(mesh::Array{Int64, 1},
                            is_shift::Array{Int64, 1},
                            is_time_reversal::Int64,
                            lattice::Array{Float64, 2},
                            positions::Array{Float64, 2},
                            types::Array{Int64, 1},
                            num_atom::Int64,
                            symprec::Float64=1e-5)
    return spg_get_ir_reciprocal_mesh(mesh, is_shift, is_time_reversal,
                                    lattice, positions, types, num_atom, symprec)
end

function ir_reciprocal_mesh(mesh::Array{Int64, 1},
                            is_shift::Array{Bool, 1},
                            is_time_reversal::Bool,
                            lattice::Array{Float64, 2},
                            positions::Array{Float64, 2},
                            types::Array{Int64, 1},
                            num_atom::Int64,
                            symprec::Float64=1e-5)
    #
    is_shift = [flag ? 1 : 0 for flag in is_shift]
    is_time_reversal = is_time_reversal ? 1 : 0

    return spg_get_ir_reciprocal_mesh(mesh, is_shift, is_time_reversal,
                                    lattice, positions, types, num_atom, symprec)
end

end #module LibSymspg
