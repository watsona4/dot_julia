## utility functions


## https://discourse.julialang.org/t/efficient-tuple-concatenation/5398/7
@inline tuplejoin(x) = x
@inline tuplejoin(x, y) = (x..., y...)
@inline tuplejoin(x, y, z...) = (x..., tuplejoin(y, z...)...)

# powmod(g, q, f) but q can be BigInt,,,
# compute a^n mod m
function _powermod(a, n::S, m) where {S<:Integer}
    ## basically powermod in intfuncs.jl with wider type signatures
    n < 0 && throw(DomainError())
    n == 0 && return one(m)

    _,b = divrem(a,m)
    iszero(b) && return b
    
    t = prevpow(2,n)::S

    local r = one(a)
    while true
        if n >= t
            _,r = divrem(r * b, m)
            n -= t
        end
        t >>>= 1
        t <= 0 && break
        _,r = divrem(r * r, m)
    end
    r
end
