mutable struct polynomial_t <: LCMType
    timestamp::Int64
    num_coefficients::Int32
    coefficients::Vector{Float64}
end

@lcmtypesetup(polynomial_t,
    coefficients => (num_coefficients,),
)
