mutable struct support_data_t <: LCMType
    timestamp::Int64
    body_name::String
    num_contact_pts::Int32
    contact_pts::Matrix{Float64}
    total_normal_force_upper_bound::Float32
    total_normal_force_lower_bound::Float32
    support_logic_map::SVector{4, Bool}
    use_support_surface::Bool
    support_surface::SVector{4, Float32}
    mu::Float64
end

@lcmtypesetup(support_data_t,
    contact_pts => (3, num_contact_pts),
)
