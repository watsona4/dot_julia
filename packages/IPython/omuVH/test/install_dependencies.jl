if VERSION >= v"0.7.0-"
    # Adding Pkg in test/REQUIRE would be an error in 0.6.  Using
    # Project.toml still has some gotchas.  So:
    Pkg = Base.require(Base.PkgId(Base.UUID(0x44cfe95a1eb252eab672e2afdf69b78f), "Pkg"))
end

# Let PyCall.jl use Python interpreter from Conda.jl
# See: https://github.com/JuliaPy/PyCall.jl
ENV["PYTHON"] = ""
Pkg.build("PyCall")

using Compat: @info
using IPython

IPython.install_dependency("pytest"; force=true)
IPython.install_dependency("ipython"; force=true)
if get(ENV, "CONDA_JL_VERSION", "") == "2"
    # For IPython.testing.globalipapp
    IPython.install_dependency("mock"; force=true)
end

# Build PyCall again, since above installation could have changed
# Python versions.
Pkg.build("PyCall")

if VERSION >= v"0.7.0-"
    @info "PyCall/deps/build.log:"
    print(read(
        joinpath(dirname(dirname(pathof(IPython.PyCall))), "deps", "build.log"),
        String))
end
