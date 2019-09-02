module ConstrainedProblems

import ..OptimizationProblem
import ..ConstraintData

examples = Dict{AbstractString, OptimizationProblem}()

hs9_obj(x::AbstractVector) = sin(π*x[1]/12) * cos(π*x[2]/16)
hs9_c!(c::AbstractVector, x::AbstractVector) = (c[1] = 4*x[1]-3*x[2]; c)
hs9_h!(h, x, λ) = h

function hs9_obj_g!(g::AbstractVector, x::AbstractVector)
    g[1] = π/12 * cos(π*x[1]/12) * cos(π*x[2]/16)
    g[2] = -π/16 * sin(π*x[1]/12) * sin(π*x[2]/16)
    g
end
function hs9_obj_h!(h::AbstractMatrix, x::AbstractVector)
    v = hs9_obj(x)
    h[1,1] = -π^2*v/144
    h[2,2] = -π^2*v/256
    h[1,2] = h[2,1] = -π^2 * cos(π*x[1]/12) * sin(π*x[2]/16) / 192
    h
end

function hs9_jacobian!(J, x)
    J[1,1] = 4
    J[1,2] = -3
    J
end

# TODO: IPNewtons  gets stuck when using x0 = [0,0].
#       Check with Tim if this also happened before?
examples["HS9"] = OptimizationProblem("HS9",
                                      hs9_obj,
                                      hs9_obj_g!,
                                      nothing,
                                      hs9_obj_h!,
                                      ConstraintData(hs9_c!, hs9_jacobian!, hs9_h!,
                                                     [], [], [0.0], [0.0]),
                                      [-1.0,2.0],#[0.0, 0.0],
                                      [-3.0,-4.0],#[[12k-3, 16k-4] for k in (0, 1, -1)], # any integer k will do...
                                      hs9_obj([-3.0,-4.0]),
                                      true,
                                      true)

# Hock and Schittkowski problem number 39.
#
#   Source:
#   Problem 39 in
#   W. Hock and K. Schittkowski,
#   Test examples for nonlinear programming codes,
#   Lectures Notes in Economics and Mathematical Systems 187,
#   Springer Verlag, Heidelberg, 1981.
#
#   classification LOR2-AN-4-2
#
#
# Original source:
# Example 8.7 in
# A. Miele, J.L Tiete, and A.V. Levy
# COMPARISON OF SEVERAL GRADIENT ALGORITHMS FOR MATHEMATICAL PROGRAMMING PROBLEMS, 1972
#

hs39_obj(x) = -x[1]
function hs39_obj_g!(g::AbstractVector{T}, x) where T
    g[1] = -T(1)
    g[2:4] .= T(0)
    g
end
function hs39_obj_h!(h::AbstractMatrix{T}, x) where T
    h .= T(0)
    h
end

function hs39_c!(c, x)
    c[1] = x[2] - x[1]^3 - x[3]^2
    c[2] = x[1]^2 - x[2] - x[4]^2
    c
end

function hs39_jacobian!(J::AbstractMatrix{T}, x) where T
    J[1,1] = -3x[1]^2
    J[1,2] = T(1)
    J[1,3] = -2x[3]

    J[2,1] = 2x[1]
    J[2,2] = -T(1)
    J[2,4] = -2x[4]

    J
end

function hs39_h!(h::AbstractMatrix{T}, x, λ) where T
    h[1,1] += -λ[1]*6*x[1]
    h[3,3] += -λ[1]*2

    h[1,1] += λ[2]*2
    h[4,4] += -λ[2]*2

    h
end


examples["HS39"] = OptimizationProblem("HS39",
                                       hs39_obj,
                                       hs39_obj_g!,
                                       nothing,
                                       hs39_obj_h!,
                                       ConstraintData(hs39_c!, hs39_jacobian!, hs39_h!,
                                                      [], [], [0.0,0.0], [0.0,0.0]),
                                       fill(2.0,4),
                                       [1.0, 1.0, 0, 0],
                                       hs39_obj([1.0, 1.0, 0, 0]),
                                       true,
                                       true)



end  # module
