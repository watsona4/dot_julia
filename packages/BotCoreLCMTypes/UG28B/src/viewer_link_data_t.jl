mutable struct viewer_link_data_t <: LCMType
    name::String
    robot_num::Int32
    num_geom::Int32
    geom::Vector{viewer_geometry_data_t}
end

@lcmtypesetup(viewer_link_data_t,
    geom => (num_geom,)
)
