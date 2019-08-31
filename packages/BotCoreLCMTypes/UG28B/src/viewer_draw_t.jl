mutable struct viewer_draw_t <: LCMType
    timestamp::Int64
    num_links::Int32
    link_name::Vector{String}
    robot_num::Vector{Int32}
    position::Matrix{Float32}
    quaternion::Matrix{Float32}
end

@lcmtypesetup(viewer_draw_t,
    link_name => (num_links,),
    robot_num => (num_links,),
    position => (num_links, 3),
    quaternion => (num_links, 4),
)
