module InPlace

# -----------------------------------------------------------------------------
#
# API
#
# -----------------------------------------------------------------------------
"""
    a = inplace!(op, a, b...)

Compute and return `op(b...)`. If `a` is mutable, possibly modify its value
in-place.

In the case where `a` is mutable, it is an implementation detail whether its
value is actually modified, and for this reason, one should always _also_
assign the result of this call to `a`. Moreover, one should use it only
on values for which the current stackframe holds the only reference; e.g.
by using `deepcopy`.
"""
inplace!(op, a, b...) = op(b...)

"""
    a = inclusiveinplace!(op, a, b...)

Compute and return `op(a, b...)`. If `a` is mutable, possibly modify its value
in-place.

In the case where `a` is mutable, it is an implementation detail whether its
value is actually modified, and for this reason, one should always _also_
assign the result of this call to `a`. Moreover, one should use it only
on values for which the current stackframe holds the only reference; e.g.
by using `deepcopy`.
"""
inclusiveinplace!(op, a, b...) = inplace!(op, a, a, b...)

"""
    @inplace a = f(args...)
    @inplace a += expr

Compute `f(args...)` resp. `+(a, expr)` and assign the result to `a`. If `a` is
mutable, possibly modify its value in-place.

In the case where `a` is mutable, it is an implementation detail whether its
value is actually modified. For this reason, one should use this operation
only on values for which the current stackframe holds the only reference; e.g.
by using `deepcopy`.
"""
macro inplace(assignment)
    if assignment.head == :(=)
        @assert assignment.args[2].head == :call
        tgt  = esc(assignment.args[1])
        op   = esc(assignment.args[2].args[1])
        srcs = map(esc, assignment.args[2].args[2:end])
        call = :(
            $inplace!($op, $tgt)
        )
        for src in srcs
            push!(call.args, src)
        end
        return :( $tgt = $call )
    else
        opchar, eqchar = string(assignment.head)
        @assert eqchar == '='
        @assert length(assignment.args) == 2

        tgt = esc(assignment.args[1])
        op  = esc(Symbol(opchar))
        src = esc(assignment.args[2])
        call = :(
            $inclusiveinplace!($op, $tgt, $src)
        )
        return :( $tgt = $call )
    end
end

export @inplace

# -----------------------------------------------------------------------------
#
# Implementations for BigInt
#
# -----------------------------------------------------------------------------
inplace!(::typeof(+), a::BigInt, b::BigInt, c::BigInt) = (Base.GMP.MPZ.add!(a,b,c); a)
inplace!(::typeof(-), a::BigInt, b::BigInt, c::BigInt) = (Base.GMP.MPZ.sub!(a,b,c); a)
inplace!(::typeof(*), a::BigInt, b::BigInt, c::BigInt) = (Base.GMP.MPZ.mul!(a,b,c); a)
inplace!(::typeof(*), a::BigInt, b::BigInt, c::Int) = (Base.GMP.MPZ.mul_si!(a,b,c); a)

inplace!(op, a::BigInt, b::BigInt, c::Integer) = inplace!(op, a, b, convert(BigInt, c))

inplace!(::typeof(+), a::BigInt, b::BigInt) = (Base.GMP.MPZ.set!(a,b); a)
inplace!(::typeof(-), a::BigInt, b::BigInt) = (Base.GMP.MPZ.neg!(a,b); a)



end # module
