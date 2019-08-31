using CondaBinDeps, Compat, Compat.Test, BinDeps
import CondaBinDeps.Conda

# manager for test environment
testenv = :CondaBinDeps_test
TestManager = CondaBinDeps.EnvManager{testenv}

if "libpng" in Conda._installed_packages(testenv)
    Conda.rm("libpng", testenv)
end

# force installation by Conda
empty!(BinDeps.defaults)
push!(BinDeps.defaults, BinDeps.PackageManager)

@BinDeps.setup
libpng = library_dependency("libpng", aliases = ["libpng16"])
provides(TestManager, "libpng", libpng)
@BinDeps.install Dict(:libpng => :libpng_lib)

@test "libpng" in Conda._installed_packages(testenv)

deps = joinpath(@__DIR__, "deps.jl")
@test isfile(deps)
include(deps)
@test isfile(libpng_lib)
