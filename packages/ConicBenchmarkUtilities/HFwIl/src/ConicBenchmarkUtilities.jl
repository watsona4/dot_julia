__precompile__()

module ConicBenchmarkUtilities

using GZip

if VERSION < v"0.7.0-"
    import Compat: undef
    import Compat: @warn
end

if VERSION > v"0.7.0-"
    using SparseArrays
    using LinearAlgebra
    # this is required because findall return type changed in v0.7
    function SparseArrays.findnz(A::AbstractMatrix)
        I = findall(!iszero, A)
        return (getindex.(I, 1), getindex.(I, 2), A[I])
    end
end

export readcbfdata, cbftompb, mpbtocbf, writecbfdata
export remove_zero_varcones, socrotated_to_soc, remove_ints_in_nonlinear_cones, dualize

include("cbf_input.jl")
include("cbf_output.jl")
include("mpb.jl")
include("preprocess_mpb.jl")
include("convex_to_cbf.jl")
include("jump_to_cbf.jl")

end # module
