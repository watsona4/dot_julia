@static if VERSION >= v"0.7.0-"
    using Pkg
else
    macro info(x)
        :(info($(esc(x))))
    end
end

if VERSION < v"0.7.0-"
    @info "Pkg.clone(pwd())"
    Pkg.clone(pwd())
end

@info "Pkg.build(IPython)"
if VERSION >= v"1.1.0-rc1"
    Pkg.build("IPython", verbose=true)
else
    Pkg.build("IPython")
end

using IPython

if VERSION >= v"0.7.0-"
    @info "PyCall/deps/build.log:"
    print(read(
        joinpath(dirname(dirname(pathof(IPython.PyCall))), "deps", "build.log"),
        String))
end

@info "show_versions.jl"
include("show_versions.jl")
