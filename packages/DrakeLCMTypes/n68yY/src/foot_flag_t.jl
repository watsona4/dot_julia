mutable struct foot_flag_t <: LCMType
    timestamp::Int64
    right::Bool
    left::Bool
end

@lcmtypesetup(foot_flag_t)
