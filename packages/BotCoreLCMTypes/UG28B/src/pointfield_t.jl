mutable struct pointfield_t <: LCMType
    name::String
    offset::Int32
    datatype::Int8
    count::Int32
end

@lcmtypesetup(pointfield_t)
