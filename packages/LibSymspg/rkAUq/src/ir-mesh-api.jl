function spg_get_ir_reciprocal_mesh(mesh::Array{Int64, 1},
                            is_shift::Array{Int64, 1},
                            is_time_reversal::Int64,
                            lattice::Array{Float64, 2},
                            positions::Array{Float64, 2},
                            types::Array{Int64, 1},
                            num_atom::Int64,
                            symprec::Float64=1e-5)
    #
    mesh = Base.cconvert( Array{Int32,1}, mesh)
    is_shift = Base.cconvert( Array{Int32,1}, is_shift )
    types = Base.cconvert( Array{Int32,1}, types)
    num_atom = Base.cconvert( Int32, num_atom )
    is_time_reversal = Base.cconvert( Int32, is_time_reversal )

    # Prepare for output
    nkpts = prod(mesh)
    grid_address = zeros(Int32,3,nkpts)
    ir_mapping_table = zeros(Int32,nkpts)

    num_ir =
    ccall((:spg_get_ir_reciprocal_mesh, libsymspg), Int32,
          (Ptr{Int32}, Ptr{Int32}, Ptr{Int32},
           Ptr{Int32}, Int32, Ptr{Float64}, Ptr{Float64},
           Ptr{Int32}, Int32, Float64),
           grid_address, ir_mapping_table, mesh, is_shift, is_time_reversal,
           lattice, positions, types, num_atom, symprec)

    return Base.cconvert(Int64, num_ir),
           Base.cconvert(Array{Int64,2}, grid_address),
           Base.cconvert(Array{Int64,1}, ir_mapping_table)
end
