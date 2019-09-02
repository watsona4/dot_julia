
export IndeterminateException

"""
    IndeterminateException(msg = "")

Exception raised when the result of a numerical operation on a `NumberInterval`
is indeterminate.

See documentation of `Indeterminate` for information on enabling this behavior.
"""
struct IndeterminateException <: Exception
    msg
end
IndeterminateException() = IndeterminateException("")

intercept_exception(::Any) = true

"""
    missing_or_exception(msg = nothing)

Returns `Base.missing` by default.

To throw an `IndeterminateException()` instead (*only* for debugging purposes),
extend the `intercept_exception()` function from this module by defining:
```julia
    NumberIntervals.intercept_exception(::IndeterminateException) = false
```
Note that this changes behavior *globally*, across all packages processing
`NumberInterval`s and therefore should never be used in production code.
"""
function missing_or_exception(msg = nothing)
    exc = IndeterminateException(msg)
    intercept_exception(exc) && return missing
    throw(exc)
end
