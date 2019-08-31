# This file reproduces just enough functionality of BEAST to allow
# for meaningful testing of non-trivial user cases
using StaticArrays
using CompScienceMeshes

struct RTRefSpace{T<:Real} end

function (f::RTRefSpace{T})(x) where {T}
    u, v = parametric(x)
    j = jacobian(x)

    tu = tangents(x,1)
    tv = tangents(x,2)

    d = 2/j

    return SVector((
        ((tu*(u-1) + tv*v    ) / j, d),
        ((tu*u     + tv*(v-1)) / j, d),
        ((tu*u     + tv*v    ) / j, d)
    ))
end

numfunctions(::RTRefSpace) = 3
