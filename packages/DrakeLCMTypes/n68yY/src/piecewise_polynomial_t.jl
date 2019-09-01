mutable struct piecewise_polynomial_t  <: LCMType
    timestamp::Int64
    num_breaks::Int32
    breaks::Vector{Float64}
    num_segments::Int32
    polynomial_matrices::Vector{polynomial_matrix_t}
end

@lcmtypesetup(piecewise_polynomial_t,
    breaks => (num_breaks,),
    polynomial_matrices => (num_segments,)
)
