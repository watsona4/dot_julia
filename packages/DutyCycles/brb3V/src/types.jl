"""

This is the type of numbers (Real and Complex) that are allowed for
values of a [`DutyCycle`](@ref). To construct more general numbers,
e.g. to attach units using the package `Unitful`, use a DutyCycle as
underlying type for such a more general type rather than using e.g. a
`Unitful` number as a value type of a DutyCycle. Note that this is not
only possible but happens automatically when you try to attach units.

"""
const NoDimNum = Union{Real, Complex}


"""

Internally used type for known, dimensionless quantities.

"""
const DimlessNum =
    Union{NoDimNum, Unitful.DimensionlessQuantity}

"""

The abstract type on which stub methods are defined to allow other
packages to overwrite their behavior.

!!! info "To Do"
    To Do: Ensure we have these stubs!

This supertype is parametrized by the constituent types `T` for
durations such as the period ("time"), `U` for fractional periods
("unitless"), and `V` for values assumed by the dutycycle.

!!! warning
    Make no assumptions: An DutyCycle is by definition a rather
    atypical number in the context of numbers usually
    encountered. Hence many concepts, such as the ordered nature of
    `Real` numbers do not apply: You cannot e.g. expect an operator
    such as isless (`<`) to be defined for DutyCycles.

"""
abstract type AbstractDutyCycle{T,U,V} <: Number where {
    T<:Real, U<:Real, V<:NoDimNum
}
end

"""

A coherent DutyCycle has a well-defined phases associated with the
values it assumes.

"""
abstract type
    AbstractCoherentDutyCycle{T,U,V} <: AbstractDutyCycle{T,U,V}
end

"""
An incoherent DutyCycle does not have phases associated with the
values it assumes. Instead, it only has effective (fractional)
durations that each of its values is assumed over a cycle period _in
total_, but not necessarily (and not usually) in one go.
"""
abstract type
    AbstractIncoherentDutyCycle{T,U,V} <: AbstractDutyCycle{T,U,V}
end

"""

Internally used type alias to simplify checking for built-in number
types which produce exact ratios, i.e. those of type
`ExactNumber`. Use e.g. as `(a isa ExactNumber && b isa ExactNumber) ?
a//b : a/b`.

"""
const ExactBuiltinReal = Union{Integer, Rational}
