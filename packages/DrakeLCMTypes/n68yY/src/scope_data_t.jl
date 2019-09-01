mutable struct scope_data_t <: LCMType
    scope_id::Int64
    num_points::Int32
    linespec::String
    resetOnXval::Bool
    xdata::Float64
    ydata::Float64
end

@lcmtypesetup(scope_data_t)
