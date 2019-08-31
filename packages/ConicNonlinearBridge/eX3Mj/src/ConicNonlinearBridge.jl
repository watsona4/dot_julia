__precompile__()
module ConicNonlinearBridge

using MathProgBase
using JuMP

using Compat.LinearAlgebra
using Compat.SparseArrays

if VERSION > v"0.7.0-"
    # this is required because findall return type changed in v0.7
    function SparseArrays.findnz(A::AbstractMatrix)
        I = findall(!iszero, A)
        return (getindex.(I, 1), getindex.(I, 2), A[I])
    end
end

include("nonlinear_to_conic.jl")

end # module
