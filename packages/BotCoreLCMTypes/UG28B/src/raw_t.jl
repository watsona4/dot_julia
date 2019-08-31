mutable struct raw_t <: LCMType
    utime::Int64
    length::Int32
    data::Vector{UInt8}
end

@lcmtypesetup(raw_t,
    data => (length,)
)
