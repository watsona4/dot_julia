module CoordinateSystem

using LinearAlgebra

export CSys

struct CSys
    O::Vector{Float64}
    x::Vector{Float64}
    y::Vector{Float64}
    z::Vector{Float64}
    T::Matrix{Float64} #transorm_matrix
end

function CSys(o::Vector{Float64},p₁::Vector{Float64},p₂::Vector{Float64})
    v₁=p₁-o
    v₂=p₂-o
    if abs(v₁⋅v₂/norm(v₁)/norm(v₂))==1
        error("Two vectors should not be parallel!")
    end
    x=v₁/norm(v₁)
    z=v₁×v₂
    z=z/norm(z)
    y=z×x
    T=[reshape(x,1,3);
        reshape(y,1,3);
        reshape(z,1,3)]
    CSys(o,x,y,z,T)
end

end
