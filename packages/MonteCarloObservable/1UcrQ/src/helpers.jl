"""
    fileext(filepath::AbstractString)

Extracts lowercase file extension from given filepath.
Extension is defined as "everything after the last dot".
"""
function fileext(filepath::AbstractString)
    filename = basename(filepath)
    return lowercase(filename[end-something(findfirst(isequal('.'), reverse(filename)), 0)+2:end])
end




"""
Basically a limited but much more secure version of `eval(Meta.parse(s))`.
"""
function jltype(s::AbstractString)
    try
        return types[s]
    catch KeyError
        error("Unknown observable eltype \"$(s)\".")
    end
end


# String -> Julia type mapping
const types = Dict(
    "Bool"                        => Bool,
    "Int64"                       => Int64,
    "Float64"                     => Float64,
    "ComplexF64"                  => ComplexF64,
    "Complex{Float64}"            => Complex{Float64},
    "Int32"                       => Int32,
    "Float32"                     => Float32,
    "ComplexF32"                  => ComplexF32,
    "Vector{Bool}"                => Array{Bool,1},
    "Matrix{Bool}"                => Array{Bool,2},
    "Array{Bool,1}"               => Array{Bool,1},
    "Array{Bool,2}"               => Array{Bool,2},
    "Array{Bool,3}"               => Array{Bool,3},
    "Array{Bool,4}"               => Array{Bool,4},
    "Array{Bool,5}"               => Array{Bool,5},
    "Vector{Int}"                 => Array{Int,1},
    "Matrix{Int}"                 => Array{Int,2},
    "Array{Int,1}"                => Array{Int,1},
    "Array{Int,2}"                => Array{Int,2},
    "Array{Int,3}"                => Array{Int,3},
    "Array{Int,4}"                => Array{Int,4},
    "Array{Int,5}"                => Array{Int,5},
    "Vector{Int64}"               => Array{Int64,1},
    "Matrix{Int64}"               => Array{Int64,2},
    "Array{Int64,1}"              => Array{Int64,1},
    "Array{Int64,2}"              => Array{Int64,2},
    "Array{Int64,3}"              => Array{Int64,3},
    "Array{Int64,4}"              => Array{Int64,4},
    "Array{Int64,5}"              => Array{Int64,5},
    "Vector{Float64}"             => Array{Float64,1},
    "Matrix{Float64}"             => Array{Float64,2},
    "Array{Float64,1}"            => Array{Float64,1},
    "Array{Float64,2}"            => Array{Float64,2},
    "Array{Float64,3}"            => Array{Float64,3},
    "Array{Float64,4}"            => Array{Float64,4},
    "Array{Float64,5}"            => Array{Float64,5},
    "Vector{Complex{Float64}}"    => Array{Complex{Float64},1},
    "Matrix{Complex{Float64}}"    => Array{Complex{Float64},2},
    "Array{Complex{Float64},1}"   => Array{Complex{Float64},1},
    "Array{Complex{Float64},2}"   => Array{Complex{Float64},2},
    "Array{Complex{Float64},3}"   => Array{Complex{Float64},3},
    "Array{Complex{Float64},4}"   => Array{Complex{Float64},4},
    "Array{Complex{Float64},5}"   => Array{Complex{Float64},5}
)





"""
Thin wrapper type used in `JLD.writeas` to dump the contained vector as a higher-dimensional matrix.
"""
struct TimeSeriesSerializer{T}
    v::Vector{T}
end
@inline JLD.writeas(x::TimeSeriesSerializer{T}) where T<:AbstractArray = cat(x.v..., dims=ndims(T)+1)
@inline JLD.writeas(x::TimeSeriesSerializer{T}) where T<:Number = x.v