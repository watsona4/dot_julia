mutable struct viewer_load_robot_t <: LCMType
    num_links::Int32
    link::Vector{viewer_link_data_t}
end

@lcmtypesetup(viewer_load_robot_t,
    link => (num_links,)
)
