mutable struct polynomial_matrix_t <: LCMType
    timestamp::Int64
    rows::Int32
    cols::Int32
    polynomials::Matrix{polynomial_t}
end

@lcmtypesetup(polynomial_matrix_t,
    polynomials => (rows, cols),
)
