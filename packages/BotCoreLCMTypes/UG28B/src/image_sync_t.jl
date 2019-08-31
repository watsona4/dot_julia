mutable struct image_sync_t <: LCMType
    utime::Int64
end

@lcmtypesetup(image_sync_t)
