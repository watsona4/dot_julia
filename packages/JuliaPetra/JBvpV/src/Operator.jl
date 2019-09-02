export Operator
export getDomainMap, getRangeMap, apply!, apply
export TransposeMode, NO_TRANS, TRANS, CONJ_TRANS, isTransposed, applyConjugation



"""
Tells JuliaPetra to use the transpose or conjugate transpose of the matrix
"""
@enum TransposeMode NO_TRANS=1 TRANS=2 CONJ_TRANS=3

"""
    isTransposed(mode::TransposeMode)::Bool

Checks whether the given TransposeMode is transposed
"""
@inline isTransposed(mode::TransposeMode) = mode != NO_TRANS

"""
    applyConjugation(mode::TraseposeMode, val)

If mode is `CONJ_TRANS`, the take the conjugate.
Otherwise, just return the value.
"""
function applyConjugation(mode::TransposeMode, val)
    if mode == CONJ_TRANS
        conj(val)
    else
        val
    end
end

applyConjugation(mode::TransposeMode, val::Real) = val

"""
Operator is a description of all types that have a specific set of methods.

All Operator types must implement the following methods (with Op standing in for the Operator):

    apply!(Y::MultiVector{Data, GID, PID, LID}, operator::Op{Data, GID, PID, LID}, X::MultiVector{Data, GID, PID, LID}, mode::TransposeMode, alpha::Data, beta::Data)
Computes ``Y = α\\cdot A^{mode}\\cdot X + β\\cdot Y``, with the following exceptions
* If beta == 0, apply MUST overwrite Y, so that any values in Y (including NaNs) are ignored.
* If alpha == 0, apply MAY short-circuit the operator, so that any values in X (including NaNs) are ignored


    getDomainMap(operator::Op{Data, GID, PID, LID})::BlockMap{GID, PID, LID}
Returns the BlockMap associated with the domain of this operation

    getRangeMap(operator::Op{Data, GID, PID, LID})::BlockMap{GID, PID, LID}
Returns the BlockMap associated with the range of this operation
"""
const Operator = Any #allow Operator to be documented


"""
    apply!(Y::MultiVector, operator, X::MultiVector, mode::TransposeMode=NO_TRANS, alpha=1, beta=0)
    apply!(Y::MultiVector, operator, X::MultiVector, alpha=1, beta=0)

Computes ``Y = α\\cdot A^{mode}\\cdot X + β\\cdot Y``, with the following exceptions:
* If beta == 0, apply MUST overwrite Y, so that any values in Y (including NaNs) are ignored.
* If alpha == 0, apply MAY short-circuit the operator, so that any values in X (including NaNs) are ignored
"""
function apply! end


function apply!(Y::MultiVector{Data, GID, PID, LID}, operator::Any, X::MultiVector{Data, GID, PID, LID}, mode::TransposeMode=NO_TRANS, alpha::Data=Data(1)) where {Data <: Number, GID <: Integer, PID <: Integer, LID <: Integer}
    apply!(Y, operator, X, mode, alpha, Data(0))
end

function apply!(Y::MultiVector{Data, GID, PID, LID}, operator::Any, X::MultiVector{Data, GID, PID, LID}, alpha::Data, beta::Data=Data(0)) where {Data <: Number, GID <: Integer, PID <: Integer, LID <: Integer}
    apply!(Y, operator, X, NO_TRANS, alpha, beta)
end

"""
    apply(Y::MultiVector,operator, X::MultiVector,  mode::TransposeMode=NO_TRANS, alpha=1, beta=0)
    apply(Y::MultiVector, operator, X::MultiVector, alpha=1, beta=0)

As [`apply!`](@ref) except returns a new array for the results
"""
function apply(Y::MultiVector{Data, GID, PID, LID}, operator::Any, X::MultiVector{Data, GID, PID, LID}, mode::TransposeMode=NO_TRANS, alpha::Data=Data(1), beta::Data=Data(0))::MultiVector{Data, GID, PID, LID} where {Data <: Number, GID <: Integer, PID <: Integer, LID <: Integer}
    Y = copy(Y)
    apply!(Y, operator, X, mode, alpha, beta)
    Y
end

function apply(Y::MultiVector{Data, GID, PID, LID}, operator::Any, X::MultiVector{Data, GID, PID, LID}, alpha::Data, beta=Data(0))::MultiVector{Data, GID, PID, LID} where {Data <: Number, GID <: Integer, PID <: Integer, LID <: Integer}
    apply(Y, operator, X, NO_TRANS, alpha, beta)
end
