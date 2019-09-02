module Input

using ..FEStructure
using ..LoadCase

function parse_add_node(s::String)
    words=split(a,",")
    id=words[2]
    x=words[3]
    y=words[4]
    z=words[5]
    add_node!(structure, id, x, y, z)
end

function parse_add_uniaxial_metal(s::String)
    add_uniaxial_metal!(structure,id,E,ν,ρ,α)
end

function parse_add_general_section!(s::String)
end

function parse_add_beam_section!(s::String)
end

function parse_add_node!(s::String)
end

function parse_set_nodal_mass!(s::String)
end

function set_nodal_restraint!(s::String)
end

function set_nodal_spring!(s::String)
end

function add_beam!(s::String)
end

function set_beam_release!(s::String)
end

function set_beam_orient!(s::String)
end

function add_quad!(s::String)
end

function set_quad_rotation!(s::String)
end

function add_tria!(s::String)
end

function set_tria_rotation!(s::String)
end

function add_static_case!(s::String)
end

function add_modal_case!(s::String)
end

function add_buckling_case!(s::String)
end

function add_time_history_case!(s::String)
end

function add_nodal_force!(s::String)
end

function add_beam_strain!(s::String)
end

function add_beam_distributed!(s::String)
end

function set_modal_params!(s::String)
end

function set_buckling_params!(s::String)
end

function set_time_history_params!(s::String)
end
