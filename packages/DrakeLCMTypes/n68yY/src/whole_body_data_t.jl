mutable struct whole_body_data_t <: LCMType
    timestamp::Int64

    num_positions::Int32
    q_des::Vector{Float32}

    spline::piecewise_polynomial_t

    num_constrained_dofs::Int32
    constrained_dofs::Vector{Int32}
end

@lcmtypesetup(whole_body_data_t,
    q_des => (num_positions,),
    constrained_dofs => (num_constrained_dofs,),
)
