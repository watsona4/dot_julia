mutable struct simulation_command_t <: LCMType
    timestamp::Int64
    command_type::Int8
    string_data::String
    num_float_data::Int32
    float_data::Vector{Float32}
end

@lcmtypesetup(simulation_command_t,
    float_data => (num_float_data,),
)
