using LinearAlgebra

using MathOptInterface
const MOI = MathOptInterface
const CI = MOI.ConstraintIndex
const VI = MOI.VariableIndex

const MOIU = MOI.Utilities


# SeDuMi solves the primal/dual pair
# min c'x,       max b'y
# s.t. Ax = b,   c - A'x ∈ K
#       x ∈ K
# where K is a product of Zeros, Nonnegatives, SecondOrderCone,
# RotatedSecondOrderCone and PositiveSemidefiniteConeTriangle

# This wrapper copies the MOI problem to the SeDuMi dual so the natively
# supported supported sets are `VectorAffineFunction`-in-`S` where `S` is one
# of the sets just listed above.

mutable struct Solution
    x::Vector{Float64}
    y::Vector{Float64}
    slack::Vector{Float64}
    objective_value::Float64
    dual_objective_value::Float64
    objective_constant::Float64
    info::Dict{String, Any}
end

# Used to build the data with allocate-load during `copy_to`.
# When `optimize!` is called, a the data is passed to SeDuMi
# using `sedumi` and the `ModelData` struct is discarded
mutable struct ModelData
    m::Int # Number of rows/constraints of SeDuMi dual/MOI primal
    n::Int # Number of cols/variables of SeDuMi primal/MOI dual
    I::Vector{Int} # List of rows of A'
    J::Vector{Int} # List of cols of A'
    V::Vector{Float64} # List of coefficients of A
    c::Vector{Float64} # objective of SeDuMi primal/MOI dual
    objective_constant::Float64 # The objective is min c'x + objective_constant
    b::Vector{Float64} # objective of SeDuMi dual/MOI primal
end

# This is tied to SeDuMi's internal representation
mutable struct ConeData
    K::Cone
    sum_q::Int # cached value of `sum(q)`
    sum_r::Int # cached value of `sum(r)`
    sum_s2::Int # cached value of `sum(s.^2)`
    nrows::Dict{Int, Int} # The number of rows of each vector sets, this is used
                          # by `constraint_rows` to recover the number of rows
                          # used by a constraint when getting `ConstraintPrimal`
                          # or `ConstraintDual`.
    function ConeData()
        new(Cone(0, 0, Float64[], Float64[], Float64[]),
            0, 0, 0, Dict{Int, Int}())
    end
end

mutable struct Optimizer <: MOI.AbstractOptimizer
    cone::ConeData
    maxsense::Bool
    data::Union{Nothing, ModelData} # only non-`Nothing` between `MOI.copy_to`
                                    # and `MOI.optimize!`.
    sol::Union{Nothing, Solution}
    silent::Bool
    options::Dict{Symbol, Any}
    function Optimizer(; kwargs...)
        optimizer = new(ConeData(), false, nothing, nothing, false, Dict{Symbol, Any}())
        for (key, value) in kwargs
            MOI.set(optimizer, MOI.RawParameter(key), value)
        end
        return optimizer
    end

end

MOI.get(::Optimizer, ::MOI.SolverName) = "SeDuMi"

function MOI.set(optimizer::Optimizer, param::MOI.RawParameter, value)
    optimizer.options[param.name] = value
end
function MOI.get(optimizer::Optimizer, param::MOI.RawParameter)
    return optimizer.options[param.name]
end

MOI.supports(::Optimizer, ::MOI.Silent) = true
function MOI.set(optimizer::Optimizer, ::MOI.Silent, value::Bool)
    optimizer.silent = value
end
MOI.get(optimizer::Optimizer, ::MOI.Silent) = optimizer.silent

function MOI.is_empty(optimizer::Optimizer)
    return !optimizer.maxsense && optimizer.data === nothing
end
function MOI.empty!(optimizer::Optimizer)
    optimizer.maxsense = false
    optimizer.data = nothing # It should already be nothing except if an error is thrown inside copy_to
    optimizer.sol = nothing
end

MOIU.supports_allocate_load(::Optimizer, copy_names::Bool) = !copy_names

function MOI.supports(
    ::Optimizer,
    ::Union{MOI.ObjectiveSense,
            MOI.ObjectiveFunction{MOI.SingleVariable},
            MOI.ObjectiveFunction{MOI.ScalarAffineFunction{Float64}}})
    return true
end

function MOI.supports_constraint(
    ::Optimizer, ::Type{MOI.VectorAffineFunction{Float64}},
    ::Type{<:Union{MOI.Zeros, MOI.Nonnegatives, MOI.SecondOrderCone,
                   MOI.RotatedSecondOrderCone,
                   MOI.PositiveSemidefiniteConeTriangle}})
    return true
end

function MOI.copy_to(dest::Optimizer, src::MOI.ModelLike; kws...)
    return MOIU.automatic_copy_to(dest, src; kws...)
end

# Computes cone dimensions
function constraint_offset(cone::ConeData,
                      ci::CI{<:MOI.AbstractFunction, MOI.Zeros})
    return ci.value
end
#_allocate_constraint: Allocate indices for the constraint `f`-in-`s`
# using information in `cone` and then update `cone`
function _allocate_constraint(cone::ConeData, f, s::MOI.Zeros)
    ci = Int(cone.K.f)
    cone.K.f += MOI.dimension(s)
    return ci
end
function constraint_offset(cone::ConeData,
                      ci::CI{<:MOI.AbstractFunction, <:MOI.Nonnegatives})
    return Int(cone.K.f) + ci.value
end
function _allocate_constraint(cone::ConeData, f, s::MOI.Nonnegatives)
    ci = cone.K.l
    cone.K.l += MOI.dimension(s)
    return ci
end
function constraint_offset(cone::ConeData,
                      ci::CI{<:MOI.AbstractVectorFunction,
                             <:MOI.SecondOrderCone})
    return Int(cone.K.f) + Int(cone.K.l) + ci.value
end
function _allocate_constraint(cone::ConeData, f, s::MOI.SecondOrderCone)
    ci = cone.sum_q
    push!(cone.K.q, s.dimension)
    cone.sum_q += s.dimension
    return ci
end
function constraint_offset(cone::ConeData,
                      ci::CI{<:MOI.AbstractVectorFunction,
                             <:MOI.RotatedSecondOrderCone})
    return Int(cone.K.f) + Int(cone.K.l) + cone.sum_q + ci.value
end
function _allocate_constraint(cone::ConeData, f, s::MOI.RotatedSecondOrderCone)
    ci = cone.sum_r
    push!(cone.K.r, s.dimension)
    cone.sum_r += MOI.dimension(s)
    return ci
end
function constraint_offset(cone::ConeData,
                      ci::CI{<:MOI.AbstractFunction,
                             <:MOI.PositiveSemidefiniteConeTriangle})
    return Int(cone.K.f) + Int(cone.K.l) + cone.sum_q + cone.sum_r + ci.value
end
function _allocate_constraint(cone::ConeData, f,
                              s::MOI.PositiveSemidefiniteConeTriangle)
    ci = cone.sum_s2
    push!(cone.K.s, s.side_dimension)
    cone.sum_s2 += s.side_dimension^2
    return ci
end
function constraint_offset(optimizer::Optimizer, ci::CI)
    return constraint_offset(optimizer.cone, ci::CI)
end
function MOIU.allocate_constraint(
    optimizer::Optimizer, f::F, s::S) where {F <: MOI.AbstractFunction,
                                             S <: MOI.AbstractSet}
    return CI{F, S}(_allocate_constraint(optimizer.cone, f, s))
end

# `dimension` -> `side_dimension`, see
# http://www.juliaopt.org/MathOptInterface.jl/v0.8.1/apireference/#MathOptInterface.PositiveSemidefiniteConeTriangle
triangle_side_dimension(n) = div(isqrt(1 + 8n) - 1, 2)
square_side_dimension(n) = isqrt(n)

# Matrix indices -> Index in vectorized form
function triangle_map(i::Integer, j::Integer)
    if i < j
        return triangle_map(j, i)
    else
        # See http://www.juliaopt.org/MathOptInterface.jl/v0.8.1/apireference/#MathOptInterface.PositiveSemidefiniteConeTriangle
        return div((i - 1) * i, 2) + j
    end
end
function square_map(i::Integer, j::Integer, n::Integer)
    if i < j
        return square_map(j, i, n)
    else
        return i + (j - 1) * n
    end
end

function copy_upper_triangle(x, n, map_from, map_to)
    y = zeros(eltype(x), map_to(n, n))
    for i in 1:n, j in 1:i
        y[map_to(i, j)] = x[map_from(i, j)]
    end
    return y
end
function square_to_triangle(x, n=square_side_dimension(length(x)))
    return copy_upper_triangle(x, n, (i, j) -> square_map(i, j, n),
                               triangle_map)
end
function triangle_to_square(x, n=triangle_side_dimension(length(x)))
    return copy_upper_triangle(x, n, triangle_map, (i, j) -> square_map(i, j, n))
end

function triangle_to_square_indices(x::AbstractVector{<:Integer}, n)
    y = similar(x)
    map = square_to_triangle(1:n^2, n)
    for i in eachindex(y)
        y[i] = map[x[i]]
    end
    return y
end

# Scale coefficients depending on rows index on symmetric packed upper triangular form
# coef: List of coefficients
# rev: if true, we unscale instead (e.g. divide by √2 instead of multiply for PSD cone)
# rows: List of row indices
# d: dimension of set
function _scale_coefficients(coef::AbstractVector, rev::Bool, rows::AbstractVector,
                    d::Integer)
    scaling = rev ? 0.5 : 2.0
    output = copy(coef)
    diagidx = BitSet()
    for i in 1:d
        push!(diagidx, triangle_map(i, i))
    end
    for i in 1:length(output)
        if !(rows[i] in diagidx)
            output[i] *= scaling
        end
    end
    return output
end
# Unscale the coefficients in `coef` with respective rows in `rows` for a set `s`
function scale_coefficients(coef, s::MOI.PositiveSemidefiniteConeTriangle,
                   rows)
    return _scale_coefficients(coef, false, rows, s.side_dimension)
end
# Unscale the coefficients of `coef` in symmetric packed upper triangular form
function unscale_coefficients(coef)
    len = length(coef)
    return _scale_coefficients(coef, true, 1:len, triangle_side_dimension(len))
end

output_index(t::MOI.VectorAffineTerm) = t.output_index
variable_index_value(t::MOI.ScalarAffineTerm) = t.variable_index.value
variable_index_value(t::MOI.VectorAffineTerm) = variable_index_value(t.scalar_term)
coefficient(t::MOI.ScalarAffineTerm) = t.coefficient
coefficient(t::MOI.VectorAffineTerm) = coefficient(t.scalar_term)
# constraint_rows: Recover the number of rows used by each constraint.
# When, the set is available, simply use MOI.dimension
constraint_rows(s::MOI.AbstractVectorSet) = 1:MOI.dimension(s)
constraint_rows(s::MOI.PositiveSemidefiniteConeTriangle) = 1:(s.side_dimension^2)
# When only the index is available, use the `optimizer.ncone.nrows` field
function constraint_rows(optimizer::Optimizer,
                         ci::CI{<:MOI.AbstractVectorFunction,
                                <:MOI.AbstractVectorSet})
    return 1:optimizer.cone.nrows[constraint_offset(optimizer, ci)]
end

function MOIU.load_constraint(optimizer::Optimizer, ci::MOI.ConstraintIndex,
                              f::MOI.VectorAffineFunction,
                              s::MOI.AbstractVectorSet)
    @assert MOI.output_dimension(f) == MOI.dimension(s)
    A = sparse(output_index.(f.terms), variable_index_value.(f.terms),
               coefficient.(f.terms))
    # `sparse` combines duplicates with `+` but does not remove zeros created so
    # we call `dropzeros!`.
    dropzeros!(A)
    I, J, V = findnz(A)
    offset = constraint_offset(optimizer, ci)
    rows = constraint_rows(s)
    optimizer.cone.nrows[offset] = length(rows)
    i = offset .+ rows
    c = f.constants
    if s isa MOI.PositiveSemidefiniteConeTriangle
        c = scale_coefficients(c, s, 1:MOI.dimension(s))
        c = triangle_to_square(c, s.side_dimension)
        V = scale_coefficients(V, s, I)
        I = triangle_to_square_indices(I, s.side_dimension)
    end
    # The SeDuMi format is `b - Ax ∈ cone` so we take `-V`
    optimizer.data.c[i] = c
    append!(optimizer.data.I, offset .+ I)
    append!(optimizer.data.J, J)
    append!(optimizer.data.V, -V)
end

function MOIU.allocate_variables(optimizer::Optimizer, nvars::Integer)
    optimizer.cone = ConeData()
    optimizer.sol = nothing
    return VI.(1:nvars)
end

function MOIU.load_variables(optimizer::Optimizer, nvars::Integer)
    cone = optimizer.cone
    m = Int(cone.K.f) + Int(cone.K.l) + cone.sum_q + cone.sum_r + cone.sum_s2
    I = Int[]
    J = Int[]
    V = Float64[]
    c = zeros(m)
    b = zeros(nvars)
    optimizer.data = ModelData(m, nvars, I, J, V, c, 0., b)
end

function MOIU.allocate(optimizer::Optimizer, ::MOI.ObjectiveSense,
                       sense::MOI.OptimizationSense)
    optimizer.maxsense = sense == MOI.MAX_SENSE
end
function MOIU.allocate(::Optimizer, ::MOI.ObjectiveFunction,
                       ::MOI.Union{MOI.SingleVariable,
                                   MOI.ScalarAffineFunction{Float64}})
end

function MOIU.load(::Optimizer, ::MOI.ObjectiveSense, ::MOI.OptimizationSense)
end
function MOIU.load(optimizer::Optimizer, ::MOI.ObjectiveFunction,
                   f::MOI.SingleVariable)
    MOIU.load(optimizer,
              MOI.ObjectiveFunction{MOI.ScalarAffineFunction{Float64}}(),
              MOI.ScalarAffineFunction{Float64}(f))
end
function MOIU.load(optimizer::Optimizer, ::MOI.ObjectiveFunction,
                   f::MOI.ScalarAffineFunction)
    c0 = Vector(sparsevec(variable_index_value.(f.terms), coefficient.(f.terms),
                          optimizer.data.n))
    optimizer.data.objective_constant = f.constant
    optimizer.data.b = optimizer.maxsense ? c0 : -c0
    return nothing
end

function MOI.optimize!(optimizer::Optimizer)
    cone = optimizer.cone
    m = optimizer.data.m
    n = optimizer.data.n
    if m == n
        # If m == n, SeDuMi thinks we give A'.
        # See https://github.com/sqlp/sedumi/issues/42#issuecomment-451300096
        A = sparse(optimizer.data.I, optimizer.data.J, optimizer.data.V, m, n)
    else
        A = sparse(optimizer.data.J, optimizer.data.I, optimizer.data.V, n, m)
    end
    c = optimizer.data.c
    objective_constant = optimizer.data.objective_constant
    b = optimizer.data.b

    # Allows GC to free optimizer.data before A is loaded to SeDuMi
    optimizer.data = nothing

    options = optimizer.options
    if optimizer.silent
        options = copy(options)
        options[:fid] = 0
    end

    x, y, info = sedumi(A, b, c, optimizer.cone.K; options...)

    objective_value = (optimizer.maxsense ? 1 : -1) * dot(b, y)
    dual_objective_value = (optimizer.maxsense ? 1 : -1) * dot(c, x)
    optimizer.sol = Solution(x, y, c - A' * y, objective_value,
                             dual_objective_value, objective_constant, info)
end

function MOI.get(optimizer::Optimizer, ::MOI.SolveTime)
    return optimizer.sol.info["cpusec"]
end
function MOI.get(optimizer::Optimizer, ::MOI.RawStatusString)
    return string("feasratio = ", optimizer.sol.info["feasratio"],
                  ", pinf = ", optimizer.sol.info["pinf"],
                  ", dinf = ", optimizer.sol.info["dinf"],
                  "numerr = ", optimizer.sol.info["numerr"])
end

# Implements getter for result value and statuses
# SeDuMI returns one of the following values (based on SeDuMi_Guide_11 by Pólik):
# feasratio:  1.0 problem with complementary solution
#            -1.0 strongly infeasible problem
#             between -1.0 and 1.0 nasty problem
# pinf = 1.0 : y is infeasibility certificate => SeDuMi primal/MOI dual is infeasible
# dinf = 1.0 : x is infeasibility certificate => SeDuMi dual/MOI primal is infeasible
# pinf = 0.0 = dinf : x and y are near feasible
# numerr: 0 desired accuracy (specified by pars.eps) is achieved
#         1 reduced accuracy (specified by pars.bigeps) is achieved
#         2 failure due to numerical problems

function MOI.get(optimizer::Optimizer, ::MOI.TerminationStatus)
    if optimizer.sol isa Nothing
        return MOI.OPTIMIZE_NOT_CALLED
    end
    pinf      = optimizer.sol.info["pinf"]
    dinf      = optimizer.sol.info["dinf"]
    numerr    = optimizer.sol.info["numerr"]
    if numerr == 2
        return MOI.NUMERICAL_ERROR
    end
    @assert iszero(numerr) || isone(numerr)
    accurate = iszero(numerr)
    if isone(pinf)
        if accurate
            return MOI.DUAL_INFEASIBLE
        else
            return MOI.ALMOST_DUAL_INFEASIBLE
        end
    end
    if isone(dinf)
        if accurate
            return MOI.INFEASIBLE
        else
            return MOI.ALMOST_INFEASIBLE
        end
    end
    @assert iszero(pinf) && iszero(dinf)
    # TODO when do we return SLOW_PROGRESS ?
    #      Maybe we should use feasratio
    if accurate
        return MOI.OPTIMAL
    else
        return MOI.ALMOST_OPTIMAL
    end
end

function MOI.get(optimizer::Optimizer, ::MOI.ObjectiveValue)
    value = optimizer.sol.objective_value
    if !MOIU.is_ray(MOI.get(optimizer, MOI.PrimalStatus()))
        value += optimizer.sol.objective_constant
    end
    return value
end
function MOI.get(optimizer::Optimizer, ::MOI.DualObjectiveValue)
    value = optimizer.sol.dual_objective_value
    if !MOIU.is_ray(MOI.get(optimizer, MOI.DualStatus()))
        value += optimizer.sol.objective_constant
    end
    return value
end

function MOI.get(optimizer::Optimizer,
                 attr::Union{MOI.PrimalStatus, MOI.DualStatus})
    if optimizer.sol isa Nothing
        return MOI.NO_SOLUTION
    end
    pinf      = optimizer.sol.info["pinf"]
    dinf      = optimizer.sol.info["dinf"]
    numerr    = optimizer.sol.info["numerr"]
    if numerr == 2
        return MOI.UNKNOWN_RESULT_STATUS
    end
    @assert iszero(numerr) || isone(numerr)
    accurate = iszero(numerr)
    if isone(attr isa MOI.PrimalStatus ? pinf : dinf)
        if accurate
            return MOI.INFEASIBILITY_CERTIFICATE
        else
            return MOI.NEARLY_INFEASIBILITY_CERTIFICATE
        end
    end
    if isone(attr isa MOI.PrimalStatus ? dinf : pinf)
        return MOI.INFEASIBLE_POINT
    end
    @assert iszero(pinf) && iszero(dinf)
    if accurate
        return MOI.FEASIBLE_POINT
    else
        return MOI.NEARLY_FEASIBLE_POINT
    end
end
function MOI.get(optimizer::Optimizer, ::MOI.VariablePrimal, vi::VI)
    optimizer.sol.y[vi.value]
end
function MOI.get(optimizer::Optimizer, ::MOI.ConstraintPrimal,
                 ci::CI{<:MOI.AbstractFunction, S}) where S <: MOI.AbstractSet
    offset = constraint_offset(optimizer, ci)
    rows = constraint_rows(optimizer, ci)
    primal = optimizer.sol.slack[offset .+ rows]
    if S == MOI.PositiveSemidefiniteConeTriangle
        primal = unscale_coefficients(square_to_triangle(primal))
    end
    return primal
end

function MOI.get(optimizer::Optimizer, ::MOI.ConstraintDual,
                 ci::CI{<:MOI.AbstractFunction, S}) where S <: MOI.AbstractSet
    offset = constraint_offset(optimizer, ci)
    rows = constraint_rows(optimizer, ci)
    dual = optimizer.sol.x[offset .+ rows]
    if S == MOI.PositiveSemidefiniteConeTriangle
        tmp = dual
        dual = square_to_triangle(dual)
        n = square_side_dimension(length(rows))
        for i in 1:n, j in 1:(i-1)
            # Add lower diagonal dual. It should be equal to upper diagonal dual
            # but `unscale_coefficients` will divide by 2 so it will do the mean
            dual[triangle_map(i, j)] += tmp[i + (j-1) * n]
        end
        dual = unscale_coefficients(dual)
    end
    return dual
end

MOI.get(optimizer::Optimizer, ::MOI.ResultCount) = 1
