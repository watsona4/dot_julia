mutable struct system_status_t <: LCMType
    utime::Int64
    system::Int8
    importance::Int8
    frequency::Int8
    value::String
end

@lcmtypesetup(system_status_t)
