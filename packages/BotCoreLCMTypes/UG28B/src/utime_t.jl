mutable struct utime_t <: LCMType
    utime::Int64
end

@lcmtypesetup(utime_t)
