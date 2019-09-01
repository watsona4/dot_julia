mutable struct quadrotor_output_t <: LCMType
    timestamp::Int64
    position::SVector{3, Float64}
    orientation::SVector{4, Float64}
    twist::SVector{6, Float64}
    accelerometer::SVector{3, Float64}
    gyroscope::SVector{3, Float64}
end

@lcmtypesetup(quadrotor_output_t)
