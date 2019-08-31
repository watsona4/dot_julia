mutable struct viewer_command_t <: LCMType
    command_type::Int8
    command_data::String
end

@lcmtypesetup(viewer_command_t)
