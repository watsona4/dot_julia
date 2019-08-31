VERSION < v"0.7.0-beta2.199" && __precompile__(true)
module Nullables

if !isdefined(Base, :NullSafeTypes)
    include("nullable.jl")
else
    using Base: NullSafeTypes
end

export Nullable, NullException, isnull, unsafe_get

end # module
