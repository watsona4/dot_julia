abstract type AbstractPolynomial{N, T} end

Base.broadcastable(p::AbstractPolynomial) = Ref(p)

"""
```math
\\int_{0}^{t} p\\left(\\tau\\right) e^{c \\tau} d\\tau
```

Can be found using integration by parts.
"""
@inline function exponential_integral(p::AbstractPolynomial{N}, c, t; inv_c = inv(c), exp_c_t=exp(c * t)) where N
    if N === 1
        return inv_c * constant(p) * (exp_c_t - 1)
    else
        return inv_c * (p(t) * exp_c_t - constant(p) - exponential_integral(derivative(p), c, t; inv_c=inv_c, exp_c_t=exp_c_t))
    end
end
