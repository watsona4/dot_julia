module LibYAML

using Libdl

# Load `deps.jl`, complaining if it does not exist
const depsjl_path = joinpath(@__DIR__, "..", "deps", "deps.jl")
if !isfile(depsjl_path)
    error("LibYAML not installed properly, run Pkg.build(\"LibYAML\"), restart Julia, and try again")
end
include(depsjl_path)

# Module initialization function
function __init__()
    # Always check your dependencies from `deps.jl`
    check_deps()
end



"""
Get the library version as a string.

The function returns the pointer to a static string of the form
`X.Y.Z`, where `X` is the major version number, `Y` is a minor version
number, and `Z` is the patch version number.
"""
function get_version_string()
    unsafe_string(ccall((:yaml_get_version_string, libyaml), Cstring, ()))
end

"""
Get the library version numbers.

Returns a tuple `(major, minor, patch)`.
"""
function get_version()
    major = Ref{Cint}(0)
    minor = Ref{Cint}(0)
    patch = Ref{Cint}(0)
    ccall((:yaml_get_version, libyaml),
          Cvoid, (Ref{Cint}, Ref{Cint}, Ref{Cint}), major, minor, patch)
    (Int(major[]), Int(minor[]), Int(patch[]))
end

end
