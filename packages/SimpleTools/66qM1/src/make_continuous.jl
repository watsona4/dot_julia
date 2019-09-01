export make_continuous!

"""
`make_continuous!(vals,mod)` assumes that the list of numbers in `vals`
should represent a continuous stream of numbers, but with ambiguity modulo `mod`.
For example, they are the angles of a continuous list of complex values, but there
is an ambiguity modulo 2π. This function adjusts the values so they
appear continuous.

For finer control, use `make_continuous!(vals,mod,thresh)` where `thresh` is
the maximum allowable difference between consecutive entries in `val`.
"""
function make_continuous!(vals::Array{T,1}, mod::Real, thresh::Real) where T
    @assert mod>0 "mod must be positive, not $mod"
    @assert thresh>0 "threshold must be positive, not $thresh"
    @assert thresh<mod/2 "threshold must be less than half the modulus, not $thresh"

    nvals = length(vals)
    for j=2:nvals
        while abs(vals[j-1]-vals[j]) > thresh
            if vals[j] < vals[j-1]
                vals[j] += mod
            else
                vals[j] -= mod
            end
        end
    end
    nothing
end
make_continuous!(vals::Array{T,1}, mod::Real) where T = make_continuous!(vals, mod, mod/5)
