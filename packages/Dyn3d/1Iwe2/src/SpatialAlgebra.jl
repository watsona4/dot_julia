module SpatialAlgebra

export TransMatrix, Mfcross

# use registered packages
using DocStringExtensions
using LinearAlgebra

"""
    TransMatrix(v::Vector,X::Matrix,X_2::Matrix)
This module contain several linear algebra functions used in 6d spatial
linear algebra using 6d vector v[theta_x, theta_y, theta_z, x, y, z], get transformation
matrix X.
"""
function TransMatrix(v::Vector{T},X::Matrix{T},X_2::Matrix{T}) where T <: AbstractFloat
    # check input size
    if length(v) != 6 error("TransMatrix method need input vector length 6") end

    # tmp memory
    E_temp = Matrix{Int}(I, 3, 3)
    X .= 0.0
    X_2 .= 0.0

    # rotation
    θ = view(v,1:3); r = view(v,4:6)
    E₁ = copy(E_temp)
    E₂ = copy(E_temp)
    E₃ = copy(E_temp)

    if θ[1] != 0.
        E₁ = [1. 0. 0.; 0. cos(θ[1]) sin(θ[1]); 0. -sin(θ[1]) cos(θ[1])]
    end
    if θ[2] != 0.
        E₂ = [cos(θ[2]) 0. -sin(θ[2]); 0. 1. 0.; sin(θ[2]) 0. cos(θ[2])]
    end
    if θ[3] != 0.
        E₃ = [cos(θ[3]) sin(θ[3]) 0.; -sin(θ[3]) cos(θ[3]) 0.; 0. 0. 1.]
    end
    E = E₃*E₂*E₁

    # translation
    rcross = [0. r[3] -r[2]; -r[3] 0. r[1]; r[2] -r[1] 0.]

    # combine, return X
    X[1:3,1:3] .= E
    X[4:6,4:6] .= E
    X_2[1:3,1:3] .= E_temp
    X_2[4:6,1:3] .= rcross
    X_2[4:6,4:6] .= E_temp

    return X*X_2
end

#-------------------------------------------------------------------------------
# 6d motion vector m cross 6d force vector f
function Mfcross(m::Vector{T}, f::Vector{T}) where T <: AbstractFloat
    ω = view(m,1:3)
    v = view(m,4:6)
    ωcross = [0. -ω[3] ω[2]; ω[3] 0. -ω[1]; -ω[2] ω[1] 0.]
    vcross = [0. -v[3] v[2]; v[3] 0. -v[1]; -v[2] v[1] 0.]
    p = Vector{T}(undef,6)
    p[1:3] = ωcross*f[1:3] + vcross*f[4:6]
    p[4:6] = ωcross*f[4:6]
    return p
end



end
